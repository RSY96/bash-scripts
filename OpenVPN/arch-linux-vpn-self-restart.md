Perfecto 🙌, te armo un **README** en estilo profesional, con pasos claros, buenas prácticas y los comandos completos.

---

# 📘 README – OpenVPN Auto-Restart cada 15 minutos en Arch Linux

Este documento explica cómo configurar un **script de reinicio de OpenVPN** y un **timer de systemd** que lo ejecute automáticamente cada 15 minutos. También incluye cómo usarlo manualmente cuando quieras renovar tu IP al instante.

---

## 📂 Estructura de archivos

* `~/.local/bin/vpnreset` → Script ejecutable para reiniciar OpenVPN y mostrar la nueva IP.
* `~/.config/systemd/user/vpnreset.service` → Servicio systemd que ejecuta el script.
* `~/.config/systemd/user/vpnreset.timer` → Timer que lanza el servicio cada 15 minutos.

---

## ⚙️ Instalación

Ejecuta este bloque de comandos:

```bash
# Crear directorios si no existen
mkdir -p ~/.local/bin ~/.config/systemd/user

# 1. Crear el script manual
cat > ~/.local/bin/vpnreset <<'EOF'
#!/bin/bash
# Reinicia OpenVPN y muestra la nueva IP pública
sudo systemctl restart openvpn-client@openvpn.service
sleep 3
echo "Nueva IP pública:"
curl -s ifconfig.me
echo
EOF
chmod +x ~/.local/bin/vpnreset

# 2. Crear el servicio systemd
cat > ~/.config/systemd/user/vpnreset.service <<'EOF'
[Unit]
Description=Reiniciar OpenVPN y renovar IP

[Service]
Type=oneshot
ExecStart=%h/.local/bin/vpnreset
EOF

# 3. Crear el timer systemd
cat > ~/.config/systemd/user/vpnreset.timer <<'EOF'
[Unit]
Description=Ejecutar vpnreset cada 15 minutos

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 4. Recargar y habilitar el timer
systemctl --user daemon-reload
systemctl --user enable --now vpnreset.timer
```

---

## ▶️ Ejecución manual

Cuando quieras renovar tu IP manualmente, ejecuta:

```bash
vpnreset
```

Esto hará:

1. Reiniciar el servicio `openvpn-client@openvpn.service`
2. Esperar 3 segundos a que levante el túnel
3. Mostrar la nueva IP pública

---

## ⏱️ Ejecución automática

El temporizador `vpnreset.timer` ejecutará el script cada **15 minutos** de forma automática.

Puedes comprobar que está activo con:

```bash
systemctl --user list-timers | grep vpnreset
```

Y ver logs de la última ejecución con:

```bash
journalctl --user -u vpnreset.service -n 20 --no-pager
```

---

## ❌ Desactivar el timer

Si en algún momento quieres desactivar la ejecución automática:

```bash
systemctl --user disable --now vpnreset.timer
```

---

✅ Con esto tendrás tanto **ejecución manual** (`vpnreset`) como **renovación automática cada 15 minutos**.

---

¿Quieres que además en el README te deje una sección con **alias de conveniencia** (ej. `vpnup`, `vpndown`, `vpnstatus`) para gestionar OpenVPN rápido desde consola?
