# Ambiente Terraform — Análise de Dados sem Complicação com AWS Athena e Glue

Ambiente de demonstração para a palestra **"Análise de Dados sem complicação com AWS Athena
e Glue"**, ministrada por **Gustavo Tavares**.

Este módulo Terraform provisiona, de ponta a ponta, um pipeline de dados serverless na AWS:

```
S3 (raw, CSV) → Glue Crawler (catalogação) → Glue ETL Job (CSV → Parquet) → Athena (SQL)
```

## Arquitetura

| Componente | Recurso Terraform | Descrição |
|---|---|---|
| S3 Raw | `aws_s3_bucket.raw` | Armazena os CSVs brutos de vendas (`vendas/ano=2024/`) |
| S3 Processed | `aws_s3_bucket.processed` | Armazena os dados transformados em Parquet, particionados por `regiao` |
| S3 Athena Results | `aws_s3_bucket.athena_results` | Armazena os resultados das queries do Athena |
| S3 Glue Scripts | `aws_s3_bucket.glue_scripts` | Armazena o script Python do ETL Job |
| Glue Database | `aws_glue_catalog_database.workshop_db` | Database lógico `workshop_db` no Data Catalog |
| Glue Crawler | `aws_glue_crawler.raw_crawler` | Descobre e cataloga o schema dos dados raw |
| Glue ETL Job | `aws_glue_job.etl_job` | Transforma CSV em Parquet e atualiza o catálogo |
| Athena Workgroup | `aws_athena_workgroup.workshop` | Ambiente isolado de execução de queries SQL |
| IAM Roles | `aws_iam_role.glue_role`, `aws_iam_role.athena_role` | Permissões mínimas necessárias para Glue e Athena |

Todos os buckets S3 possuem **Block Public Access habilitado** e as IAM Roles seguem o
princípio de **privilégio mínimo** (nenhum uso de `"*"` em `Resource` e nenhuma policy
gerenciada de amplo escopo como `AdministratorAccess` ou `AmazonS3FullAccess`).

## Estrutura do repositório

```
.
├── main.tf              # data sources e valores locais
├── variables.tf          # variáveis de entrada
├── s3.tf                 # buckets S3 e upload do dataset/script
├── iam.tf                # IAM_Glue_Role e IAM_Athena_Role
├── glue.tf                # Glue Database, Crawler e ETL Job
├── athena.tf              # Athena Workgroup
├── outputs.tf              # outputs do módulo
├── versions.tf             # versões do Terraform e do provider AWS
├── data/
│   └── vendas_sample.csv   # Sample_Dataset (dados fictícios de vendas)
├── scripts/
│   └── etl_job.py          # script PySpark do Glue_ETL_Job
├── queries/
│   ├── 01_explorar_raw.sql
│   ├── 02_total_por_categoria.sql
│   ├── 03_top_vendedores.sql
│   ├── 04_vendas_por_regiao.sql
│   └── 05_consultar_processed.sql
└── README.md
```

## Pré-requisitos

- **Terraform** >= 1.5.0 ([instruções de instalação](https://developer.hashicorp.com/terraform/install)).
- **AWS CLI** configurado (`aws configure`) ou variáveis de ambiente `AWS_ACCESS_KEY_ID` /
  `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` válidas.
- Uma conta AWS com permissões para criar/gerenciar: S3, Glue (Data Catalog, Crawler, Job),
  Athena, IAM Roles/Policies e CloudWatch Logs.
- Recomendado: usuário ou role com permissões administrativas apenas para o **deploy inicial**
  do workshop (o ambiente criado em si segue privilégio mínimo).
- Region padrão: `sa-east-1` (configurável via variável `aws_region`).

## Variáveis principais

| Variável | Default | Descrição |
|---|---|---|
| `aws_region` | `"sa-east-1"` | Região AWS de deploy |
| `workshop_prefix` | `"gtavares-workshop"` | Prefixo aplicado aos nomes dos recursos |
| `aws_account_id` | *(resolvido automaticamente)* | ID da conta AWS, usado para nomes únicos de bucket |

## Deploy

1. Clone ou copie este diretório e entre nele:

   ```bash
   cd terraform-athena-glue-workshop
   ```

2. Inicialize o Terraform (baixa o provider `hashicorp/aws`):

   ```bash
   terraform init
   ```

3. Revise o plano de execução:

   ```bash
   terraform plan
   ```

4. Aplique o plano para provisionar o ambiente:

   ```bash
   terraform apply
   ```

   Confirme digitando `yes` quando solicitado. Ao final, o Terraform exibirá os `outputs`
   com os nomes/ARNs dos buckets, do Glue Database, do Crawler, do ETL Job e do Athena
   Workgroup.

5. **Durante a demonstração ao vivo**, execute manualmente, na ordem:

   1. Rode o `Glue_Crawler` (`{workshop_prefix}-raw-crawler`) via console ou `aws glue
      start-crawler --name <nome>` para catalogar a tabela raw a partir do CSV de exemplo.
   2. Use a query `queries/01_explorar_raw.sql` no Athena (Workgroup
      `{workshop_prefix}-workgroup`) para explorar os dados brutos.
   3. Rode o `Glue_ETL_Job` (`{workshop_prefix}-etl-job`) via console ou `aws glue
      start-job-run --job-name <nome>` para gerar os dados Parquet particionados.
   4. Use as queries `queries/02_*.sql` a `queries/05_*.sql` no Athena para demonstrar
      agregações sobre os dados processados.

   > O CSV de exemplo (`data/vendas_sample.csv`) e o script do ETL
   > (`scripts/etl_job.py`) já são enviados automaticamente ao S3 pelo próprio
   > `terraform apply` — não é necessário nenhum upload manual antes da demonstração.

## Limpeza

Ao final da palestra, destrua todos os recursos provisionados para evitar custos residuais:

```bash
terraform destroy
```

Confirme digitando `yes` quando solicitado.

> **Atenção:** como os buckets `S3_Raw_Bucket` e `S3_Processed_Bucket` possuem
> versionamento habilitado, e o Athena grava resultados de query no
> `S3_Athena_Results_Bucket`, pode ser necessário esvaziar as versões dos objetos antes
> que o `terraform destroy` consiga remover os buckets, por exemplo:
>
> ```bash
> aws s3 rm s3://<nome-do-bucket> --recursive
> ```
>
> Em seguida, rode `terraform destroy` novamente caso algum bucket não tenha sido removido
> na primeira tentativa.

## Notas de segurança e custo

- Todos os buckets possuem Block Public Access habilitado nos quatro flags.
- O Glue ETL Job usa `G.1X` com 2 workers (configuração mínima) para reduzir custo durante
  a demonstração.
- O Athena Workgroup limita o volume de dados escaneado por query a 1 GiB
  (`bytes_scanned_cutoff_per_query`), evitando queries acidentalmente custosas.
- As IAM Roles não usam wildcards (`"*"`) em `Resource` nem policies gerenciadas de amplo
  escopo — apenas as ações estritamente necessárias para o fluxo do workshop.
# terraform-athena-glue-workshop
