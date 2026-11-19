# 픽셀 도구 (System.Drawing + C#) — Python 없는 PC용
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public class Px {
  public int W, H; public byte[] G; // grayscale 0-255
  public Px(string path){ using(var b=new Bitmap(path)){ W=b.Width; H=b.Height; G=new byte[W*H];
    var bb=new Bitmap(W,H,PixelFormat.Format32bppArgb); using(var g=Graphics.FromImage(bb)){ g.DrawImage(b,0,0,W,H);} 
    var d=bb.LockBits(new Rectangle(0,0,W,H),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); var a=new byte[d.Stride*H]; Marshal.Copy(d.Scan0,a,0,a.Length); bb.UnlockBits(d); bb.Dispose();
    for(int y=0;y<H;y++)for(int x=0;x<W;x++){int i=y*d.Stride+x*4; int al=a[i+3]; double v=(0.299*a[i+2]+0.587*a[i+1]+0.114*a[i]); v=v*al/255.0+255*(255-al)/255.0; G[y*W+x]=(byte)Math.Round(v);} } }
  public Px(int w,int h){W=w;H=h;G=new byte[w*h];}
  public byte this[int x,int y]{ get{return G[y*W+x];} set{G[y*W+x]=value;} }
  // rows having any pixel < thr in [x0,x1]
  public string Rows(int x0,int x1,int y0,int y1,int thr){ var sb=new System.Text.StringBuilder(); int s=-1;
    for(int y=y0;y<=y1+1;y++){ bool hit=false; if(y<=y1) for(int x=x0;x<=x1;x++) if(this[x,y]<thr){hit=true;break;}
      if(hit&&s<0)s=y; if(!hit&&s>=0){ sb.Append(s+"~"+(y-1)+" "); s=-1;} } return sb.ToString(); }
  public string Cols(int x0,int x1,int y0,int y1,int lo,int hi){ var sb=new System.Text.StringBuilder(); int s=-1;
    for(int x=x0;x<=x1+1;x++){ bool hit=false; if(x<=x1) for(int y=y0;y<=y1;y++){int v=this[x,y]; if(v>=lo&&v<=hi){hit=true;break;}}
      if(hit&&s<0)s=x; if(!hit&&s>=0){ sb.Append(s+"~"+(x-1)+" "); s=-1;} } return sb.ToString(); }
  public int Count(int x0,int x1,int y0,int y1,int lo,int hi){int n=0; for(int y=y0;y<=y1;y++)for(int x=x0;x<=x1;x++){int v=this[x,y]; if(v>=lo&&v<=hi)n++;} return n;}
  // full-width dark horizontal lines: rows where >= frac of [x0,x1] is dark
  public string HLines(int x0,int x1,int y0,int y1,int thr,double frac){ var sb=new System.Text.StringBuilder();
    for(int y=y0;y<=y1;y++){int n=0; for(int x=x0;x<=x1;x++) if(this[x,y]<thr)n++; if(n>=frac*(x1-x0+1)) sb.Append(y+" ");} return sb.ToString(); }
  public string VLines(int x0,int x1,int y0,int y1,int thr,double frac){ var sb=new System.Text.StringBuilder();
    for(int x=x0;x<=x1;x++){int n=0; for(int y=y0;y<=y1;y++) if(this[x,y]<thr)n++; if(n>=frac*(y1-y0+1)) sb.Append(x+" ");} return sb.ToString(); }
  public int FirstDarkX(int x0,int x1,int y0,int y1,int thr){ for(int x=x0;x<=x1;x++)for(int y=y0;y<=y1;y++) if(this[x,y]<thr) return x; return -1; }
  public void Fill(int x0,int y0,int x1,int y1,byte v){ for(int y=y0;y<=y1;y++)for(int x=x0;x<=x1;x++) this[x,y]=v; }
  // move block rows [ys,ye] x[x0,x1] by dy (copy via temp), source area whitened first
  public void MoveBlock(int x0,int x1,int ys,int ye,int dx,int dy){ int w=x1-x0+1,h=ye-ys+1; var t=new byte[w*h];
    for(int y=0;y<h;y++)for(int x=0;x<w;x++) t[y*w+x]=this[x0+x,ys+y];
    Fill(x0,ys,x1,ye,255); for(int y=0;y<h;y++)for(int x=0;x<w;x++) this[x0+x+dx,ys+y+dy]=t[y*w+x]; }
  public int WhitenGray(int x0,int x1,int y0,int y1,int lo){int n=0; for(int y=y0;y<=y1;y++)for(int x=x0;x<=x1;x++){int v=this[x,y]; if(v>=lo&&v<255){this[x,y]=255;n++;}} return n;}
  public void MinCol(int x,int refY,int y0,int y1){ byte r=this[x,refY]; for(int y=y0;y<=y1;y++) if(r<this[x,y]) this[x,y]=r; }
  public void MinRowCopy(int srcY,int dstY,int x0,int x1){ for(int x=x0;x<=x1;x++){ byte v=this[x,srcY]; if(v<this[x,dstY]) this[x,dstY]=v; } }
  public int[] Text(string text,string font,float emPx,bool bold,int left,int bottom,bool draw){
    int TW=1200,TH=300; using(var b=new Bitmap(TW,TH)) using(var g=Graphics.FromImage(b)){
      g.Clear(Color.White); g.TextRenderingHint=System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
      using(var f=new Font(font,emPx,bold?FontStyle.Bold:FontStyle.Regular,GraphicsUnit.Pixel)) g.DrawString(text,f,Brushes.Black,10,10);
      int x0=TW,x1=-1,y0=TH,y1=-1; for(int y=0;y<TH;y++)for(int x=0;x<TW;x++){ if(b.GetPixel(x,y).R<200){ if(x<x0)x0=x; if(x>x1)x1=x; if(y<y0)y0=y; if(y>y1)y1=y; } }
      if(draw){ for(int y=y0-2;y<=y1+2;y++)for(int x=x0-2;x<=x1+2;x++){ var c=b.GetPixel(x,y); int v=(int)Math.Round(0.299*c.R+0.587*c.G+0.114*c.B); int tx=left+(x-x0), ty=bottom-(y1-y); if(v<this[tx,ty]) this[tx,ty]=(byte)v; } }
      return new int[]{x0,y0,x1,y1}; } }
  public void Save(string path){ var bb=new Bitmap(W,H,PixelFormat.Format24bppRgb); var d=bb.LockBits(new Rectangle(0,0,W,H),ImageLockMode.WriteOnly,PixelFormat.Format24bppRgb); var a=new byte[d.Stride*H];
    for(int y=0;y<H;y++)for(int x=0;x<W;x++){int i=y*d.Stride+x*3; byte v=G[y*W+x]; a[i]=v;a[i+1]=v;a[i+2]=v;} Marshal.Copy(a,0,d.Scan0,a.Length); bb.UnlockBits(d); bb.Save(path,ImageFormat.Png); bb.Dispose(); }
}
'@
