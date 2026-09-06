"""Gemini AI service — OPTIMIZED UNTUK VPS JAKARTA"""

import json
import asyncio
import random
import time
import re
from datetime import datetime
from typing import Dict, Any, Optional, Callable

import google.generativeai as genai

from src.config.settings import settings
from src.utils.logger import logger
from src.utils.parsers import parse_transaction_locally, parse_indonesian_amount
from src.utils.timezone import now


class GeminiService:
    """Service for Gemini AI operations with fallback - OPTIMIZED."""
    
    def __init__(self):
        self.model = None
        self.vision_model = None
        self.is_initialized = False
        self.active_model = None
        self.last_error_time = 0
        self.error_count = 0
        self.max_errors = 3
        self.cache = {}  # Cache untuk hasil parsing
        self.cache_max_size = 100
        
        self._initialize()
    
    def _initialize(self):
        if not settings.is_gemini_enabled():
            logger.info("ℹ️ Gemini API tidak dikonfigurasi - menggunakan parser lokal")
            return
        
        # ============================================================
        # OPTIMASI: PAKAI MODEL TERCEPAT
        # ============================================================
        models_to_try = [
            'models/gemini-2.5-flash-lite',  # ⚡ PALING CEPAT
            'models/gemini-3.5-flash',        # ⚡ Cepat
            'models/gemini-3.6-flash',        # ⚡ Cepat
            'models/gemini-3.7-flash',        # 🐌 Lebih lambat (backup)
        ]
        
        if settings.GEMINI_MODEL and settings.GEMINI_MODEL not in models_to_try:
            models_to_try.insert(0, settings.GEMINI_MODEL)
        
        logger.info(f"🔍 Mencoba model Gemini: {models_to_try[:3]}...")
        
        for model_name in models_to_try:
            try:
                genai.configure(api_key=settings.GEMINI_API_KEY)
                self.model = genai.GenerativeModel(model_name)
                self.vision_model = self.model
                self.is_initialized = True
                self.active_model = model_name
                self.error_count = 0
                logger.info(f"✅ Gemini berhasil dengan model: {model_name}")
                return
            except Exception as e:
                error_msg = str(e).lower()
                if 'not found' in error_msg or 'no longer available' in error_msg:
                    logger.warning(f"⏭️ {model_name} tidak tersedia")
                else:
                    logger.warning(f"⚠️ Gagal {model_name}: {e}")
                continue
        
        logger.warning("⚠️ Tidak ada model Gemini yang tersedia. Menggunakan parser lokal.")
        self.is_initialized = False
    
    def _reset_if_needed(self):
        if time.time() - self.last_error_time > 60:
            self.error_count = 0
            self.last_error_time = time.time()
    
    def _get_cached(self, text: str) -> Optional[Dict[str, Any]]:
        """Ambil dari cache jika ada."""
        if text in self.cache:
            logger.debug(f"ℹ️ Cache hit: {text[:30]}...")
            return self.cache[text]
        return None
    
    def _set_cache(self, text: str, result: Dict[str, Any]):
        """Simpan ke cache."""
        if len(self.cache) >= self.cache_max_size:
            # Hapus 20% cache tertua
            keys = list(self.cache.keys())
            for key in keys[:20]:
                del self.cache[key]
        self.cache[text] = result
    
    async def call_with_retry(
        self, 
        generate_func: Callable, 
        max_retries: int = 1,  # ⚡ Kurangi retry
        base_delay: int = 1
    ) -> Any:
        """Call Gemini API with retry logic - OPTIMIZED."""
        if not self.is_initialized:
            raise Exception("Gemini API tidak dikonfigurasi")
        
        self._reset_if_needed()
        if self.error_count >= self.max_errors:
            logger.info("ℹ️ Menggunakan parser lokal (terlalu banyak error)")
            raise Exception("Terlalu banyak error")
        
        for attempt in range(max_retries + 1):
            try:
                # ⚡ TIMEOUT 10 DETIK (dari 30)
                response = await asyncio.wait_for(
                    asyncio.to_thread(generate_func),
                    timeout=10.0
                )
                self.error_count = max(0, self.error_count - 1)
                return response
            except asyncio.TimeoutError:
                logger.warning(f"⏳ Timeout, percobaan {attempt + 1}/{max_retries + 1}")
                if attempt < max_retries:
                    await asyncio.sleep(base_delay * (2 ** attempt))
                    continue
                else:
                    self.error_count += 1
                    self.last_error_time = time.time()
                    raise Exception("Request timeout")
            except Exception as e:
                error_str = str(e).lower()
                
                if 'not found' in error_str or 'no longer available' in error_str:
                    self.error_count += 1
                    self.last_error_time = time.time()
                    self._initialize()
                    if self.is_initialized:
                        logger.info("🔄 Mencoba dengan model baru...")
                        continue
                    raise Exception("Tidak ada model yang tersedia")
                
                if any(kw in error_str for kw in ['429', 'quota', 'rate', 'resource_exhausted']):
                    if attempt < max_retries:
                        delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
                        logger.warning(f"⏳ Limit kuota, coba lagi dalam {delay:.1f}s")
                        await asyncio.sleep(delay)
                        continue
                
                if attempt < max_retries:
                    delay = base_delay + random.uniform(0, 1)
                    logger.warning(f"⚠️ Error: {e}, coba lagi dalam {delay:.1f}s")
                    await asyncio.sleep(delay)
                else:
                    self.error_count += 1
                    self.last_error_time = time.time()
                    raise e
        
        raise Exception("Maksimal percobaan tercapai")
    
    async def parse_financial_data(self, text: str) -> Dict[str, Any]:
        """
        Parse financial data - OPTIMIZED.
        Local parser dulu, Gemini hanya untuk yang sulit.
        """
        # ============================================================
        # 1. CEK CACHE
        # ============================================================
        cached = self._get_cached(text)
        if cached:
            return cached
        
        # ============================================================
        # 2. LOCAL PARSER DULU (CEPAT)
        # ============================================================
        local_result = parse_transaction_locally(text)
        
        # Jika local parser menghasilkan amount yang jelas, langsung return
        if local_result.get('amount') is not None and abs(local_result['amount']) > 0:
            # Validasi: deskripsi tidak kosong
            if local_result.get('description') and len(local_result['description']) > 0:
                logger.info(f"⚡ Local parser (fast path): {text[:30]}...")
                self._set_cache(text, local_result)
                return local_result
        
        # ============================================================
        # 3. GEMINI (hanya jika perlu)
        # ============================================================
        if not self.is_initialized:
            return local_result
        
        self._reset_if_needed()
        if self.error_count >= self.max_errors:
            return local_result
        
        current_date = now()
        
        try:
            # ⚡ PROMPT PENDEK
            prompt = f"""
            Parse this Indonesian financial text: "{text}"
            Today: {current_date.strftime("%Y-%m-%d")}
            
            Return JSON only:
            {{"amount": number, "category": string, "description": string, "transaction_type": "income" or "expense", "date": "YYYY-MM-DD"}}
            
            Rules:
            - 70k=70000, 1jt=1000000
            - If unclear: category="Lainnya", type="expense"
            """
            
            response = await self.call_with_retry(
                lambda: self.model.generate_content(prompt),
                max_retries=1,
                base_delay=1
            )
            
            try:
                text_response = response.text
                if "```json" in text_response:
                    json_str = text_response.split("```json")[1].split("```")[0].strip()
                elif "```" in text_response:
                    json_str = text_response.split("```")[1].strip()
                else:
                    json_str = text_response.strip()
                
                data = json.loads(json_str)
                
                # Validasi
                if not data.get('date'):
                    data['date'] = current_date.strftime("%Y-%m-%d")
                
                if data.get('amount') is not None:
                    try:
                        amount = abs(float(data.get('amount')))
                        if data.get('transaction_type') == 'expense':
                            amount = -amount
                        data['amount'] = amount
                    except:
                        data['amount'] = local_result.get('amount')
                else:
                    data['amount'] = local_result.get('amount')
                
                if data.get('transaction_type') not in ['income', 'expense']:
                    data['transaction_type'] = local_result.get('transaction_type', 'expense')
                
                if not data.get('description'):
                    data['description'] = local_result.get('description', text)
                
                if not data.get('category'):
                    data['category'] = local_result.get('category', 'Lainnya')
                
                # Simpan ke cache
                self._set_cache(text, data)
                
                logger.info(f"✅ Gemini parsed: {data.get('description', '')[:30]}...")
                return data
                
            except json.JSONDecodeError:
                return local_result
                
        except Exception as e:
            logger.warning(f"⚠️ Gemini gagal, pakai local parser: {str(e)[:50]}")
            return local_result
    
    async def analyze_receipt(self, image_file) -> Dict[str, Any]:
        """Analyze receipt image using Gemini Vision."""
        if not self.is_initialized:
            return {"error": "Fitur scan struk tidak tersedia. Silakan catat manual."}
        
        current_date = now()
        
        # ⚡ PROMPT PENDEK UNTUK SCAN STRUK
        prompt = f"""
        Analyze this receipt image.
        Today: {current_date.strftime("%Y-%m-%d")}
        
        Return JSON:
        - "store_name": string
        - "receipt_date": YYYY-MM-DD
        - "total_amount": number
        - "items": [{"description": string, "quantity": number, "amount": number, "category": string}]
        - "transaction_type": "expense"
        """
        
        try:
            response = await self.call_with_retry(
                lambda: self.vision_model.generate_content([prompt, image_file]),
                max_retries=1,
                base_delay=2
            )
            
            try:
                text_response = response.text
                if "```json" in text_response:
                    json_str = text_response.split("```json")[1].split("```")[0].strip()
                elif "```" in text_response:
                    json_str = text_response.split("```")[1].strip()
                else:
                    json_str = text_response.strip()
                
                data = json.loads(json_str)
                
                if not data.get('receipt_date'):
                    data['receipt_date'] = current_date.strftime("%Y-%m-%d")
                
                return data
                
            except json.JSONDecodeError:
                return {"error": "Gagal memproses struk. Format tidak dikenali."}
                
        except Exception as e:
            error_str = str(e).lower()
            
            if 'quota' in error_str or '429' in error_str:
                return {"error": "Kuota Gemini habis. Silakan catat manual atau tunggu besok."}
            elif 'timeout' in error_str:
                return {"error": "Koneksi ke AI timeout. Silakan coba lagi atau catat manual."}
            elif 'not found' in error_str or 'model' in error_str:
                return {"error": "Model AI tidak tersedia. Silakan catat manual."}
            else:
                logger.error(f"Receipt analysis failed: {e}")
                return {"error": f"Gagal menganalisis gambar: {str(e)[:50]}"}
    
    def is_available(self) -> bool:
        return self.is_initialized and self.error_count < self.max_errors


gemini_service = GeminiService()
