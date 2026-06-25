from waitress import serve
from wsgi import application

print("Servidor rodando em http://127.0.0.1:6000")

serve(application, host="0.0.0.0", port=6000)