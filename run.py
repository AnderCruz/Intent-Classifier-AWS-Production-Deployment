from app import app

if __name__ == "__main__":
    print("Iniciando servidor...")
    app.run(host="0.0.0.0", port=6000, debug=True)