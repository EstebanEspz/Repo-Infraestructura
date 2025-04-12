# Repo-Infraestructura

Este repositorio contiene únicamente la **infraestructura** del proyecto para su despliegue en entorno de desarrollo basado en contenedores y servicios en la nube.

---

## Aclaraciones importantes

1. Es requisito OBLIGATORIO tener instalado Minikube, que utilice el driver de Docker y kubectl 
2. Este trabajo se ha realizado en **WSL** (Windows Subsystem for Linux).
3. Se utilizaron inicialmente carpetas en **Windows**, que luego fueron clonadas dentro del entorno **WSL**.
4. El editor utilizado fue **Visual Studio Code** en ambos entornos (Windows y Linux), junto con la extensión oficial de WSL:

   > ID de extensión → `ms-vscode-remote.remote-wsl`

---

# Guía de Despliegue - Kubernetes con Minikube

## Paso 1: Crear Carpeta en Windows
Crea una carpeta en tu Escritorio de Windows, con el nombre **"Proyecto-8Ks"**. Si queres crearla con otro nombre, tene en cuenta que vas a tener que estar muy pendiente a la hora de manejar los comandos con los directorios.

## Paso 2: Abrir Visual Studio Code
Abri Visual Studio Code y agrega la carpeta creada en el punto anterior al Espacio de trabajo.

## Paso 3: Clonar Repositorios
Con el comando `git clone <url del repositorio>` deberas clonar las carpetas que contienen la infraestructura y el Sitio Web. El comando entonces quedaria compuesto de la siguiente manera:

- Para clonar el repo de la Infraestructura -> `https://github.com/EstebanEspz/Repo-Infraestructura.git`
- Para clonar el Repo del Sitio Web -> `https://github.com/EstebanEspz/Static-Website-Fork.git`

## Paso 4: Abrir WSL
Teniendo ya todo clonado en la carpeta de **WINDOWS** es hora de abrir WSL.

## Paso 5: Crear Carpeta en WSL
En WSL, creamos una carpeta con el nombre **"Proyecto-Despliegue"** a traves del comando:

```bash
mkdir Proyecto-Despliegue
ls
```

## Paso 6: Copiar desde Windows a WSL
Ahora copiaremos el contenido de la carpeta de Windows a WSL, mediante el siguiente comando:

```bash
cp -r "<direccion de la carpeta de Windows>" ~<direccion de la carpeta de WSL>
```

Yo te voy a dejar mi comando de ejemplo para que entiendas:

```bash
cp -r "/mnt/c/Users/esteb/OneDrive/Escritorio/Proyecto-Test" ~/Proyecto-Despliegue/
```

- Aqui tenes que tener muchas cosas en cuenta, en este comando la primer parte (`/mnt/c/Users/esteb/OneDrive/Escritorio/Proyecto-Test`) corresponde a la direccion de la carpeta que tenes en Windows, por lo tanto deberia ir TU direccion de esa carpeta, y si me hiciste caso en el paso 5, no deberias cambiar el nombre de la carpeta de WSL.
- Te recomiendo chequear a traves del comando que quieras (`cd` o `tree`) que se hayan copiado correctamente las carpetas y los archivos.

## Paso 7: Abrir Visual desde WSL
Con el paso anterior listo, posicionate sobre la carpeta "Proyecto-Despliegue" y tira el comando:

```bash
code .
```

En tu terminal se deberia ver algo asi:

```bash
esteban123@LAPTOP-BSV0P1K4:~/Proyecto-Despliegue$ code .
```

Esto abrirá (si tenes la extension instalada nombrada en la aclaracion 3) una ventana de Visual con todo el directorio y todos los archivos que se ejecuta del lado de WSL. Visual te puede preguntar si confias en los autores, y deberas darle a que si.

## Paso 8: Terminal Integrada WSL
En este nuevo Visual Abierto abriremos la terminal integrada que está ya conectada al WSL. Para ello podes irte a la pestaña superior que dice "Terminal" y darle a "Nuevo Terminal" O si queres hacerlo mas rápido, `CTRL+SHIFT+Ñ` (si tenes los shortcuts por defecto).

## Paso 9: Iniciar Minikube
En esta nueva terminal, lo primero que vamos a hacer es tirar el comando:

```bash
minikube start
```

(Espera a que todo se cree, toma su tiempito)

## Paso 10: Ir a la Carpeta de Infraestructura
Ahora debes moverte hasta la carpeta que contiene la infraestructura; deberia aparecerte algo asi:

```bash
esteban123@LAPTOP-BSV0P1K4:~/Proyecto-Despliegue/Proyecto-Test/Repo-Infraestructura$
```

## Paso 11: Aplicar Manifiestos
Una vez dentro, tenemos dos caminos para elegir; podemos tirar el comando:

```bash
kubectl apply -f <nombredelarchivo.yaml>
```

o si estas dentro de la carpeta (y es lo que te recomiendo) tira el siguiente comando:

```bash
kubectl apply -R -f .
```

Esto deberia darte una salida asi:

```
deployment.apps/portal-deployment created
service/portal-service created
persistentvolume/pv-frontend created
persistentvolumeclaim/pvc-frontend created
```

## Paso 12: Verificar el Pod
Chequea que el POD se haya levantado correctamente, para eso utiliza el comando:

```bash
kubectl get pods
```

Si tiras este comando instantaneamente luego del paso 11, tal vez te salga el campo "READY" 0/1 ya que necesita un tiempo para poder crearlo; y deberas esperar a que se cree. Para chequear esto ultimo volve a tirar el mismo comando.

## Paso 13: Verificar PV y PVC
Ahora Chequea que los PV y PVC esten relacionados correctamente, para esto utiliza el comando:

```bash
kubectl get pv,pvc
```

Aca tenes que ver que el status de ambos salga en "BOUND" y que ambos STORAGECLASS digan "mi-clase".

## Paso 14: Ingresar por SSH a Minikube
```bash
minikube ssh
sudo mkdir -p /mnt/sitio-despliegue
exit
```

(No cambies nada del comando, si no el hostPath no encontrara la ruta y no funcionará).

## Paso 15: Copiar Archivos del Sitio
Ahora tendras que tirar varios comandos; lo primero que tenes que hacer es irte a WSL, y moverte hasta la carpeta donde esta el contenido de la pagina a desplegar. Para que te orientes, se tendria que ver algo asi:

```bash
~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork
```

Copia esta direccion en el portapapeles que la vamos a usar en el siguiente paso.

### Comandos:
```bash
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/index.html /mnt/sitio-despliegue/index.html
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/style.css /mnt/sitio-despliegue/style.css
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/DSC_0036.JPG /mnt/sitio-despliegue/assets/DSC_0036.JPG
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/banner-bg.jpg /mnt/sitio-despliegue/assets/banner-bg.jpg
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/banner-texture.png /mnt/sitio-despliegue/assets/banner-texture.png
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/banner-texture@2x.png /mnt/sitio-despliegue/assets/banner-texture@2x.png
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/img-banner@2x.png /mnt/sitio-despliegue/assets/img-banner@2x.png
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/img-contact-form-bg.jpg /mnt/sitio-despliegue/assets/img-contact-form-bg.jpg
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/img-prop-type@2x.jpg /mnt/sitio-despliegue/assets/img-prop-type@2x.jpg
minikube cp ~/Proyecto-Despliegue/Proyecto-Test/Static-Website-Fork/assets/logo-new.png /mnt/sitio-despliegue/assets/logo-new.png
```

## ¿Qué hace este comando?
Este comando copia el archivo que elijamos desde el entorno local de WSL (Linux dentro de Windows) hacia el sistema de archivos de la máquina virtual que corre Minikube. Nuevamente ten en cuenta todas las direcciones utilizadas de los directorios.

### Verificación:
```bash
minikube ssh
cd /mnt/sitio-despliegue/assets/
ls
exit
```

## Paso 16: Exponer Servicio en Navegador
```bash
minikube service portal-service
```

Cuando este listo, te saldrá algo como esto:

```
|-----------|----------------|-------------|---------------------------|
| NAMESPACE |      NAME      | TARGET PORT |            URL            |
|-----------|----------------|-------------|---------------------------|
| default   | portal-service |          80 | http://192.168.49.2:30001 |
|-----------|----------------|-------------|---------------------------|
🏃  Starting tunnel for service portal-service.
|-----------|----------------|-------------|------------------------|
| NAMESPACE |      NAME      | TARGET PORT |          URL           |
|-----------|----------------|-------------|------------------------|
| default   | portal-service |             | http://127.0.0.1:35125 |
|-----------|----------------|-------------|------------------------|
🎉  Opening service default/portal-service in default browser...
👉  http://127.0.0.1:35125 //Hace Ctrl + click para que te abra esa direccion en el navegador predeterminado 
```

## Paso 17: ¡Felicidades!
Felicidades concretaste el despliegue.



