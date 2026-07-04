using System;
using System.Runtime.InteropServices;

namespace gInk
{
    public static class WinTabManager
    {
        public const int WT_PACKET    = 0x7FF0;
        public const int WT_PROXIMITY = 0x7FF5;

        public const uint PK_NORMAL_PRESSURE = 0x0400;
        public const uint CXO_MESSAGES = 0x0004;
        public const uint CXO_SYSTEM   = 0x0001;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
        public struct LOGCONTEXT
        {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 40)]
            public string lcName;
            public uint lcOptions, lcStatus, lcLocks, lcMsgBase, lcDevice;
            public uint lcPktRate, lcPktData, lcPktMode, lcMoveMask;
            public uint lcBtnDnMask, lcBtnUpMask;
            public int lcInOrgX, lcInOrgY, lcInOrgZ;
            public int lcInExtX, lcInExtY, lcInExtZ;
            public int lcOutOrgX, lcOutOrgY, lcOutOrgZ;
            public int lcOutExtX, lcOutExtY, lcOutExtZ;
            public int lcSensX, lcSensY, lcSensZ;
            public int lcSysMode, lcSysOrgX, lcSysOrgY;
            public int lcSysExtX, lcSysExtY, lcSysSensX, lcSysSensY;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct PACKET { public int pkNormalPressure; }

        [StructLayout(LayoutKind.Sequential)]
        public struct AXIS
        {
            public int axMin, axMax;
            public uint axUnits;
            public float axResolution;
        }

        [DllImport("WinTab32.dll", SetLastError = true)]
        private static extern IntPtr WTOpen(IntPtr hWnd, ref LOGCONTEXT lc, bool fEnable);

        [DllImport("WinTab32.dll")]
        private static extern bool WTClose(IntPtr hCtx);

        [DllImport("WinTab32.dll")]
        private static extern int WTPacket(IntPtr hCtx, uint wSerial, ref PACKET lpPkt);

        [DllImport("WinTab32.dll")]
        private static extern bool WTInfo(uint wCategory, uint nIndex, IntPtr lpOutput);

        private const uint WTI_DEFCONTEXT = 3;
        private const uint WTI_DEVICES    = 100;
        private const uint DVC_NPRESSURE  = 15;

        private static IntPtr _hCtx = IntPtr.Zero;
        private static int    _maxPressure = 1023;
        public  static bool   IsAvailable  = false;

        public static bool Open(IntPtr hWnd)
        {
            try 
            { 
                WTInfo(0, 0, IntPtr.Zero); 
            }
            catch (DllNotFoundException) 
            { 
                return false; 
            }
            catch (Exception)
            {
                return false;
            }

            _maxPressure = ReadMaxPressure();

            LOGCONTEXT lc = new LOGCONTEXT();
            IntPtr lcPtr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(LOGCONTEXT)));
            try
            {
                WTInfo(WTI_DEFCONTEXT, 0, lcPtr);
                lc = (LOGCONTEXT)Marshal.PtrToStructure(lcPtr, typeof(LOGCONTEXT));
            }
            finally { Marshal.FreeHGlobal(lcPtr); }

            lc.lcOptions   = CXO_SYSTEM | CXO_MESSAGES;
            lc.lcMsgBase   = WT_PACKET;
            lc.lcPktData   = PK_NORMAL_PRESSURE;
            lc.lcPktMode   = 0;
            lc.lcMoveMask  = 0;
            lc.lcBtnDnMask = 0;
            lc.lcBtnUpMask = 0;
            lc.lcName      = "gInk_pressure_ctx";

            _hCtx = WTOpen(hWnd, ref lc, true);
            IsAvailable = (_hCtx != IntPtr.Zero);
            return IsAvailable;
        }

        public static void Close()
        {
            if (_hCtx != IntPtr.Zero)
            {
                WTClose(_hCtx);
                _hCtx = IntPtr.Zero;
                IsAvailable = false;
            }
        }

        public static float ReadPressure(uint serial)
        {
            if (_hCtx == IntPtr.Zero) return -1f;
            PACKET pkt = new PACKET();
            int result = WTPacket(_hCtx, serial, ref pkt);
            if (result == 0) return -1f;
            return Math.Max(0f, Math.Min(1f, pkt.pkNormalPressure / (float)_maxPressure));
        }

        private static int ReadMaxPressure()
        {
            IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(AXIS)));
            try
            {
                WTInfo(WTI_DEVICES + 0, DVC_NPRESSURE, ptr);
                AXIS ax = (AXIS)Marshal.PtrToStructure(ptr, typeof(AXIS));
                return ax.axMax > 0 ? ax.axMax : 1023;
            }
            catch { return 1023; }
            finally { Marshal.FreeHGlobal(ptr); }
        }
    }
}
