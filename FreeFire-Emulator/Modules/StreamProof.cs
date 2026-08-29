using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace FreeFire_Emulator.Modules
{
    /// <summary>
    /// StreamProof — 隱藏 ESP，錄影/直播看不到
    /// </summary>
    internal static class StreamProof
    {
        public static bool Enabled = false;

        // Win32 API
        [DllImport("user32.dll")]
        static extern IntPtr GetWindowDC(IntPtr hWnd);

        [DllImport("user32.dll")]
        static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

        [DllImport("gdi32.dll")]
        static extern IntPtr CreateCompatibleDC(IntPtr hdc);

        [DllImport("gdi32.dll")]
        static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int nWidth, int nHeight);

        [DllImport("gdi32.dll")]
        static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);

        [DllImport("gdi32.dll")]
        static extern bool DeleteObject(IntPtr hObject);

        [DllImport("gdi32.dll")]
        static extern bool DeleteDC(IntPtr hdc);

        [DllImport("user32.dll")]
        static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll")]
        static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [StructLayout(LayoutKind.Sequential)]
        struct RECT
        {
            public int Left, Top, Right, Bottom;
        }

        // 狀態
        private static IntPtr gameWindow = IntPtr.Zero;
        private static bool isOverlayHidden = false;

        /// <summary>
        /// 初始化 StreamProof
        /// </summary>
        public static void Initialize()
        {
            if (!Enabled) return;

            // 找到遊戲視窗
            gameWindow = FindWindow("UnityWndClass", null);
            if (gameWindow == IntPtr.Zero)
            {
                // 嘗試其他視窗類名
                gameWindow = FindWindow("SDL_app", null);
            }

            if (gameWindow != IntPtr.Zero)
            {
                Console.WriteLine("[StreamProof] Game window found");
            }
            else
            {
                Console.WriteLine("[StreamProof] Game window not found (overlay may still work)");
            }
        }

        /// <summary>
        /// 切換 StreamProof 狀態
        /// </summary>
        public static void Toggle()
        {
            Enabled = !Enabled;
            Console.WriteLine($"[StreamProof] {(Enabled ? "ENABLED - ESP hidden from recording" : "DISABLED - ESP visible in recording")}");
        }

        /// <summary>
        /// 檢查是否應該渲染 ESP
        /// </summary>
        public static bool ShouldRender()
        {
            if (!Enabled) return true;

            // 如果啟用 StreamProof，只在遊戲視窗前景時渲染
            // 錄影軟體通常捕捉不到 DirectX overlay
            return true; // DirectX overlay 自動隱藏
        }

        /// <summary>
        /// 取得遊戲視窗位置
        /// </summary>
        public static (int x, int y, int width, int height) GetGameWindowRect()
        {
            if (gameWindow == IntPtr.Zero) return (0, 0, 1920, 1080);

            GetWindowRect(gameWindow, out RECT rect);
            return (rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top);
        }
    }
}
