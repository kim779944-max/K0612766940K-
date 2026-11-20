# 픽셀 비교(System.Drawing) — 두 PNG 의 다른 픽셀 비율(채널 차 > tol)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class PxCmp {
  static byte[] Raw(Bitmap b, out int stride){ var r=new Rectangle(0,0,b.Width,b.Height); var d=b.LockBits(r,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); stride=d.Stride; var a=new byte[d.Stride*b.Height]; Marshal.Copy(d.Scan0,a,0,a.Length); b.UnlockBits(d); return a; }
  public static double Diff(string p1,string p2,int tol){
    using(var a=new Bitmap(p1)) using(var b=new Bitmap(p2)){
      if(a.Width!=b.Width||a.Height!=b.Height) return -1;
      int s1,s2; var x=Raw(a,out s1); var y=Raw(b,out s2); long n=0, tot=(long)a.Width*a.Height;
      for(int j=0;j<a.Height;j++) for(int i=0;i<a.Width;i++){ int o=j*s1+i*4; if(Math.Abs(x[o]-y[o])>tol||Math.Abs(x[o+1]-y[o+1])>tol||Math.Abs(x[o+2]-y[o+2])>tol) n++; }
      return (double)n/tot;
    }
  }
}
"@
