# 📊 Análise de Espaço Ocupado em Bucket S3 | S3 Bucket Space Analysis

## 📌 Descrição | Description

**PT-BR:**  
Este script PowerShell analisa o conteúdo de um bucket S3 da AWS, listando todos os arquivos de forma recursiva. Ele agrupa os arquivos por pasta, calcula o tamanho total ocupado (em Bytes, KB, MB, GB e TB), conta a quantidade de arquivos em cada pasta e exporta as informações para um arquivo CSV com timestamp. Ideal para auditorias, relatórios e controle de uso de armazenamento.

**EN:**  
This PowerShell script analyzes the contents of an AWS S3 bucket by listing all files recursively. It groups files by folder, calculates the total size used (in Bytes, KB, MB, GB, and TB), counts the number of files per folder, and exports the information to a timestamped CSV file. Ideal for audits, reporting, and storage usage monitoring.

---

## ⚙️ Como Usar | How to Use

1. Instale e configure o [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
2. Configure suas credenciais com `aws configure`.
3. Edite o script substituindo:
   - `PATH` pelo caminho onde deseja salvar o CSV.
   - `"s3://bucketname"` pelo nome real do seu bucket.
4. Execute o script no PowerShell:

##
1. Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
2. Configure your credentials with `aws configure`.
3. Edit the script by replacing:
- `PATH` with the path where you want to save the CSV.
- `"s3://bucketname"` with the actual name of your bucket.
4. Run the script in PowerShell:

---
#Saída | Output
![{68645C66-52BF-44C0-995F-9134BA134F72}](https://github.com/user-attachments/assets/4c1e4046-c4ba-4a4b-9a0e-ad95e3eb848e)



