#!/bin/bash

# ---------- MANEJO DE ERRORES ROBUSTO ----------
set -Eeuo pipefail
trap 'echo "❌ Error en la línea $LINENO. Abortando."; exit 1' ERR

# ---------- CONFIGURACIÓN ----------
Directorio_Home="$HOME"
Directorio_Proyecto="$HOME/Proyecto-Tests"

Pagina_web="Static-Website-Fork"
URL_Pagina_web="https://github.com/EstebanEspz/Static-Website-Fork.git"
Contenido_Web=("index.html" "assets" "style.css")

Infraestructura="Repo-Infraestructura"
URL_Infraestructura="https://github.com/EstebanEspz/Repo-Infraestructura.git"
Archivos_Infraestructura=("deployment.yaml" "service.yaml" "pv.yaml" "pvc.yaml")

Mount_Path="/mnt/sitio-despliegue"
Deploy_Finalizado="$Directorio_Proyecto/.deploy_done"

Minikube_Profile="sitio-statico"
Kube_Context="sitio-statico"
Kube_Namespace="sitio-web"
Entorno_Reiniciado=false

# ---------- FUNCIONES AUXILIARES ----------

check_herramientas() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "❌ Error: '$1' no está instalado o no se encuentra en el PATH."
        exit 1
    }
}

verificacion_Integridad() {
    local dir_name=$1
    shift
    local required_items=("$@")

    echo "📁 Verificando integridad de '$dir_name'..."
    if [ ! -d "$dir_name/.git" ]; then
        echo "⚠️  '$dir_name' no es un repositorio Git válido."
        return 1
    fi

    for item in "${required_items[@]}"; do
        if ! find "$dir_name" -iname "$item" | grep -q .; then
            echo "⚠️  Faltante: '$item' en '$dir_name'."
            return 1
        fi
    done

    return 0
}

reset_danios() {
    if [ "$Entorno_Reiniciado" = true ]; then
        echo "⚠️  El entorno ya fue reiniciado. Omitiendo segundo reinicio."
        return
    fi

    Entorno_Reiniciado=true
    echo "🧹 Reiniciando entorno Minikube y Kubernetes..."

    echo "🔻 Eliminando namespace '$Kube_Namespace' (si existe)..."
    kubectl delete namespace "$Kube_Namespace" --context="$Kube_Context" --ignore-not-found || true

    echo "🔥 Eliminando perfil Minikube '$Minikube_Profile'..."
    minikube delete -p "$Minikube_Profile" || true

    echo "🗑️  Eliminando repositorios locales..."
    rm -rf "$Directorio_Proyecto/$Pagina_web"
    rm -rf "$Directorio_Proyecto/$Infraestructura"
    rm -f "$Deploy_Finalizado"
}

verificacion_fallida() {
    local repo_name=$1
    local repo_url=$2
    shift 2
    local items=("$@")
    local repo_path="$Directorio_Proyecto/$repo_name"

    if ! verificacion_Integridad "$repo_path" "${items[@]}"; then
        echo "🚨 Integridad comprometida en '$repo_name'. Se reiniciará el entorno completo."
        reset_danios
        echo "📦 Clonando '$repo_name' desde $repo_url..."
        git clone "$repo_url" "$repo_path"
    else
        echo "✅ '$repo_name' verificado correctamente."
    fi
}

# ---------- INICIO ----------

echo "🔍 Verificando herramientas necesarias..."
check_herramientas git
check_herramientas kubectl
check_herramientas minikube
check_herramientas docker
echo "✅ Todas las herramientas están disponibles."

mkdir -p "$Directorio_Proyecto"
cd "$Directorio_Proyecto"

verificacion_fallida "$Pagina_web" "$URL_Pagina_web" "${Contenido_Web[@]}"
verificacion_fallida "$Infraestructura" "$URL_Infraestructura" "${Archivos_Infraestructura[@]}"

# ---------- MINIKUBE ----------
STATIC_LOCAL_PATH="$Directorio_Proyecto/$Pagina_web"

if minikube status -p "$Minikube_Profile" | grep -q "Running"; then
    echo "🟢 Minikube ya está en ejecución. Omitiendo inicio."
else
    echo "🚀 Iniciando Minikube con perfil '$Minikube_Profile' y montaje..."
    minikube start -p "$Minikube_Profile" --driver=docker \
        --mount --mount-string="$STATIC_LOCAL_PATH:$Mount_Path"
fi

kubectl config use-context "$Kube_Context"

# ---------- DESPLIEGUE ----------
cd "$Directorio_Proyecto/$Infraestructura"

if [ -f "$Deploy_Finalizado" ] && kubectl get svc portal-service -n "$Kube_Namespace" >/dev/null 2>&1; then
    echo "✅ Despliegue ya realizado y servicio 'portal-service' encontrado. Saltando despliegue."
else
    echo "🔧 Creando namespace '$Kube_Namespace' (si no existe)..."
    kubectl create namespace "$Kube_Namespace" --dry-run=client -o yaml | kubectl apply -f -

    echo "⚙️  Aplicando manifiestos en namespace '$Kube_Namespace'..."
    kubectl apply -R -f . -n "$Kube_Namespace"

    echo "⏳ Esperando creación de pods..."
    until [ "$(kubectl get pods -n "$Kube_Namespace" --no-headers 2>/dev/null | wc -l)" -gt 0 ]; do
        sleep 2
    done

    echo "🔄 Esperando que los pods estén en estado Ready..."
    kubectl wait --for=condition=Ready pod --all --timeout=180s -n "$Kube_Namespace" || {
        echo "⚠️  Algunos pods no están listos. Verificalos con 'kubectl get pods -n $Kube_Namespace'."
        kubectl get pods -n "$Kube_Namespace"
        exit 1
    }

    touch "$Deploy_Finalizado"
    echo "✅ Despliegue completado con éxito."
fi

# ---------- VERIFICACIÓN DEL VOLUMEN MONTADO EN EL POD ----------
echo "🔍 Verificando que el pod montó correctamente el volumen..."
pod_name=$(kubectl get pods -n "$Kube_Namespace" --no-headers | awk '{print $1}')
TARGET_PATH="/usr/share/nginx/html"

if kubectl exec -n "$Kube_Namespace" "$pod_name" -- ls "$TARGET_PATH/index.html" >/dev/null 2>&1; then
    echo "✅ El volumen fue montado correctamente dentro del pod."
else
    echo "❌ Error: El volumen no está montado correctamente en el pod o falta index.html en '$TARGET_PATH'."
    exit 1
fi

# ---------- SERVICIO ----------
echo "🌐 Abriendo el servicio 'portal-service' en el navegador..."
minikube service portal-service -n "$Kube_Namespace" -p "$Minikube_Profile"