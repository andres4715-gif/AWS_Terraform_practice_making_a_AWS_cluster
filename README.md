# Proyecto EKS Timer App

Este proyecto despliega un cluster EKS en AWS con una aplicación simple de cronómetro. Este README proporciona las instrucciones para desplegar, verificar y eliminar los recursos.

## How to start: 
Make a new .env file adding your AWS credentials like this: 

```shell
export TF_VAR_aws_access_key="AKIA..."
export TF_VAR_aws_secret_key="..."
```

## Prerrequisitos

- [AWS CLI](https://aws.amazon.com/cli/) instalado y configurado
- [Terraform](https://www.terraform.io/downloads.html) v1.0.0+
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) instalado

## Configuración de credenciales AWS

Hay tres formas principales de configurar las credenciales AWS para Terraform:

La mas fácil seria agregar los valores des las accesos al usuario desde AWS, que fueron agregados en el archivo .env

```bash
export TF_VAR_aws_access_key="Agregar el access_key que viene desde AWS"
export TF_VAR_aws_secret_key="agregar el secret_key que viene desde AWS"
```

## AGREGAR AQUI QUE TAMBIEN SE PUEDE CON ESTE COMANDO source .env YA QUE LOS VALORES FUERON AGREGADOS EN EL ARCHIVO .env con el comando

```bash
source .env
```

### 1. Variables de entorno

```bash
export AWS_ACCESS_KEY_ID="tu_access_key_esta_en_aws_en_las_credenciales_del_user_IAM"
export AWS_SECRET_ACCESS_KEY="tu_secret_key_esta_en_aws_en_las_credenciales_del_user_IAM"
export AWS_REGION="us-east-1"
```

### 2. Archivo de credenciales AWS
Configura el archivo ~/.aws/credentials:

```bash
[default]
aws_access_key_id = tu_access_key
aws_secret_access_key = tu_secret_key
```

Y el archivo ~/.aws/config:

```bash
[default]
region = us-east-1
```

### Despliegue de la infraestructura
1. Inicializar el directorio de trabajo de Terraform

```bash
terraform init
```

2. Verificar el plan de ejecución
```bash
terraform plan
```

3. Aplicar la configuración

```bash
terraform apply
```

** Confirma escribiendo yes cuando se te solicite. El proceso completo puede tardar entre 15-25 minutos.** 

### 4. Obtener la URL de la aplicación
Una vez completado el despliegue, puedes obtener la URL de la aplicación ya que la configuración fue agregada en el archivo main.tf:


```bash
terraform output timer_app_url
```

### Verificación del despliegue
1. Configurar kubectl para el nuevo cluster

```bash
aws eks update-kubeconfig --name demo-eks --region us-east-1
```

2. Verificar que los pods estén funcionando
```bash
kubectl get pods
```

### Deberías ver algo similar a:

```bash
NAME                         READY   STATUS    RESTARTS   AGE
timer-app-7b6d56f5b9-abcd1   1/1     Running   0          2m
timer-app-7b6d56f5b9-efgh2   1/1     Running   0          2m
```

### 3. Verificar los servicios

```bash
kubectl get services
```

```bash
NAME            TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
kubernetes      ClusterIP      10.100.0.1       <none>                                                                    443/TCP        10m
timer-service   LoadBalancer   10.100.124.175   a1b2c3d4e5f6g7h8i9j0k.us-east-1.elb.amazonaws.com                         80:30080/TCP   5m
```

** La columna EXTERNAL-IP contiene la URL del balanceador de carga donde puedes acceder a la aplicación. ** 

### Acceso a la aplicación
Abre en tu navegador la URL proporcionada en el paso anterior o la obtenida con terraform output timer_app_url.

Deberías ver una interfaz simple de cronómetro con botones para:

```bash
Iniciar
Detener
Reiniciar
```

### Limpieza de recursos
Cuando hayas terminado con la aplicación, asegúrate de eliminar todos los recursos para evitar cargos innecesarios:
```bash
terraform destroy
```

Confirma escribiendo yes cuando se te solicite. Este proceso puede tardar entre 10-15 minutos.

## Estructura del proyecto
main.tf: Configuración principal de Terraform
variables.tf: Definición de variables
outputs.tf: Definición de salidas
providers.tf: Configuración de proveedores

Solución de problemas comunes
Error de creación de nodos
Si encuentras errores durante la creación del grupo de nodos, verifica:

Límites de servicio en tu cuenta AWS
Permisos IAM adecuados
Disponibilidad de tipos de instancia en la región seleccionada
Error de conexión a la aplicación
Si no puedes conectarte a la aplicación después del despliegue:

```text
Espera unos minutos más (el balanceador de carga puede tardar en estar disponible)
Verifica que los grupos de seguridad permitan tráfico en el puerto 80
Comprueba los logs de los pods: kubectl logs deployment/timer-app
Notas adicionales
El cluster EKS se despliega en la región definida en tus credenciales AWS (por defecto: us-east-1)
Se utilizan instancias t3.medium para los nodos de trabajo
La aplicación se despliega con 2 réplicas para alta disponibilidad
```

🚀👷🏻‍♂️🛠️⚙️ Seguimos trabajando... 💥🚀
