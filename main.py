import asyncio
import websockets
import json
import base64
import random
import os
import time
from pathlib import Path
import argparse

class DroneServer:
    def __init__(self, images_folder="images"):
        self.images_folder = Path(images_folder)
        self.image_files = list(self.images_folder.glob("*.jpg")) + list(self.images_folder.glob("*.png"))
        self.current_image_index = 0
        
    def get_drone_status(self):
        return {
            "battery": random.randint(20, 100),
            "altitude": round(random.uniform(0, 50), 2),
            "speed": round(random.uniform(0, 15), 2),
            "temperature": random.randint(-10, 40),
            "gps_lat": round(random.uniform(55.7, 55.8), 6),
            "gps_lon": round(random.uniform(37.5, 37.7), 6),
            "timestamp": int(time.time())
        }
    
    def get_next_image_base64(self):
        if not self.image_files:
            return None
            
        image_path = self.image_files[self.current_image_index]
        self.current_image_index = (self.current_image_index + 1) % len(self.image_files)
        
        try:
            with open(image_path, "rb") as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                return encoded_string
        except Exception as e:
            print(f"Error reading image: {e}")
            return None
    
    async def handle_client(self, websocket):
        print(f"Client connected: {websocket.remote_address}")
        try:
            while True:
                # Отправляем статус дрона
                status_data = {
                    "type": "status",
                    "data": self.get_drone_status()
                }
                await websocket.send(json.dumps(status_data))
                
                # Отправляем изображение
                image_base64 = self.get_next_image_base64()
                if image_base64:
                    image_data = {
                        "type": "image",
                        "data": image_base64
                    }
                    await websocket.send(json.dumps(image_data))
                
                await asyncio.sleep(1)  # Интервал отправки данных
                
        except websockets.exceptions.ConnectionClosed:
            print(f"Client disconnected: {websocket.remote_address}")
        except Exception as e:
            print(f"Error: {e}")

async def main():
    # Парсинг аргументов командной строки
    parser = argparse.ArgumentParser(description="Drone WebSocket Server")
    parser.add_argument('--host', default='localhost', help='Host IP address to bind (default: localhost)')
    parser.add_argument('--port', type=int, default=8765, help='Port to bind (default: 8765)')
    args = parser.parse_args()

    # Создаем папку для изображений, если её нет
    images_folder = Path("images")
    images_folder.mkdir(exist_ok=True)
    
    server = DroneServer()
    
    # Используем 0.0.0.0 для внешнего доступа, если host не localhost
    bind_host = '0.0.0.0' if args.host != 'localhost' else 'localhost'
    print(f"Starting drone server on ws://{args.host}:{args.port} (binding to {bind_host}:{args.port})")
    async with websockets.serve(server.handle_client, bind_host, args.port):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())