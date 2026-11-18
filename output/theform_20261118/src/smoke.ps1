. "$PSScriptRoot\lib.ps1"
Open-App 'oneclick\theform.html'
try {
  Write-Output (Js "return JSON.stringify({errs:window.__errs, n:TF.BUILT.length, f:TF.BUILT.map(f=>f.name+':'+f.fields.length), sw:document.documentElement.scrollWidth})")
  Write-Output (Js "$B64JS const out=[]; for(const f of TF.BUILT){ await TF.openForm(f.id,3); document.querySelector('#sampleVals').click(); const h=await TF.exportBlob('hwpx'); const x=await TF.exportBlob('xlsx'); out.push(f.name+' hwpx='+h.size+' xlsx='+x.size);} return JSON.stringify({out, errs:window.__errs})")
} finally { Stop-CdpChrome }
