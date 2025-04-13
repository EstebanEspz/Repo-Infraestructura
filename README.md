# Repo-Infraestructura

Este repositorio contiene únicamente la **infraestructura** del proyecto para su despliegue en entorno de desarrollo basado en contenedores y servicios en la nube.

---

## Aclaraciones importantes

1. Este trabajo se ha realizado en **WSL** (Windows Subsystem for Linux), Minikube, DockerDesktop y kubectl.
2. Es requisito OBLIGATORIO tener instalados los programas mencionados en el punto anterior
3. Es requisito OBLIGATORIO tener la integracion con WSL en DockerDesktop. Para activarlo: DockerDesktop -> settings -> resources -> wsl integration
3. Se utilizaron inicialmente carpetas en **Windows**, que luego fueron clonadas dentro del entorno **WSL**.
4. El editor utilizado fue **Visual Studio Code** en ambos entornos (Windows y Linux), junto con la extensión oficial de WSL:

   > ID de extensión → `ms-vscode-remote.remote-wsl`

---

## Empezando con el Despliegue 


# Guía de Despliegue - Kubernetes con Minikube

## Paso 1: Crear Carpeta en Windows
Crea una carpeta en tu Escritorio de Windows, con el nombre **"Proyecto-8Ks"**. Si queres crearla con otro nombre, tene en cuenta que vas a tener que estar muy pendiente a la hora de manejar los comandos con los directorios.

## Paso 2: Abrir Visual Studio Code
Abri Visual Studio Code y agrega la carpeta creada en el punto anterior al Espacio de trabajo.

## Paso 3: Clonar Repositorios
Con el comando `git clone <url del repositorio>` deberas clonar las carpetas que contienen la infraestructura y el Sitio Web. El comando entonces quedaria compuesto de la siguiente manera:

- Para clonar el repo de la Infraestructura -> `git clone https://github.com/EstebanEspz/Repo-Infraestructura.git`
- Para clonar el Repo del Sitio Web -> `git clone https://github.com/EstebanEspz/Static-Website-Fork.git`

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

Esto abrirá (si tenes la extension instalada nombrada en las aclaraciones) una ventana de Visual con todo el directorio y todos los archivos ejecutándose del lado de WSL. Visual te puede preguntar si confias en los autores, y deberas darle a que si.

## Paso 8: Terminal Integrada WSL
En este nuevo Visual Abierto abriremos la terminal integrada que está ya conectada al WSL. Para ello podes irte a la pestaña superior que dice "Terminal" y darle a "Nuevo Terminal" O si queres hacerlo mas rápido, `CTRL+SHIFT+Ñ` (si tenes los shortcuts por defecto).

## Paso 9: Iniciar Minikube
En esta nueva terminal, lo primero que vamos a hacer es tirar el comando a continuacion, **PERO ANTES FIJATE BIEN LAS COSAS A TENER EN CUENTA**

```bash
minikube start --driver=docker --mount --mount-string="/home/esteban123/Proyecto-Despliegue/Proyecto-Tests/Static-Website-Fork:/mnt/sitio-despliegue" 
```

**A tener en cuenta**: Debes tener la ruta raiz **COMPLETA** donde tenes el contenido HTML (en mi caso /home/esteban123/Proyecto-Despliegue/Proyecto-Tests/Static-Website-Fork).

La ruta "/mnt/sitio-despliegue" debe ser exactamente igual a la que tenes en tu PV en hostPath (Si no cambiaste nada en ese archivo, ignora esta aclaración)

¿Como busco mi ruta raiz completa?

En la misma terminal **ANTES DE TIRAR EL COMANDO** tenes que navegar hasta el directorio "Static-Website-Fork" y ahi tiras un pwd. La ruta que te salga, copiala y pegala en el comando que estabamos trabajando arriba 

## Paso 10: Ir a la Carpeta de Infraestructura
Ahora debes moverte hasta la carpeta que contiene la infraestructura (Repo-Infraestructura); deberia aparecerte algo asi:

```bash
esteban123@LAPTOP-BSV0P1K4:~/Proyecto-Despliegue/Proyecto-Test/Repo-Infraestructura$
```

## Paso 11: Aplicar Manifiestos
Una vez dentro, tenemos dos caminos para elegir; podemos tirar el comando:

```bash
kubectl apply -f <nombredelarchivo.yaml>
```

o si estas dentro de la carpeta Repo-Infraestructura (y es lo que te recomiendo si venis respetando los pasos) tira el siguiente comando:

```bash
kubectl apply -R -f .
```
Este comando aplica todos los manifiestos YAML de forma recursiva, incluyendo el directorio actual y los subdirectorios (ahorrandote lineas de comandos)

Una vez aplicado ese comando, deberias tener una salida asi:

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

Si tiras este comando instantaneamente luego del paso 11, tal vez te salga el campo "READY" 0/1 en el pod ya que necesita un tiempo para poder crearlo. Si esto es asi, deberas esperar a que se cree y que el status READY aparezca en 1/1. Para chequear esto ultimo volve a tirar el mismo comando.

## Paso 13: Verificar PV y PVC
Ahora Chequea que los PV y PVC esten relacionados correctamente, para esto utiliza el comando:

```bash
kubectl get pv,pvc
```

Aca tenes que ver que el status de ambos salga en "BOUND" y que ambos STORAGECLASS digan "mi-clase".


## Paso 14: Exponer Servicio en Navegador
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

## Paso 15: ¡Felicidades!
Felicidades!! concretaste el despliegue. Si queres testear que es persistente, te dejé a proposito en la linea 17 del index.html (dentro del nav-bar) la palabra "Sevicio" en vez de "Servicios", corregila y guarda el cambio en el index.html y refrescá la pagina. Deberias poder ver que la palabra se corrigió correctamente!! 



