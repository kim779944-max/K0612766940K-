import type {Metadata,Viewport} from 'next'
import './globals.css'
export const metadata:Metadata={title:'성수 어반빌딩 | 빌딩노트',description:'성수 어반빌딩의 투자 지표와 층별 임대차 정보를 한눈에 살펴보세요.'}
export const viewport:Viewport={themeColor:'#0B132B',colorScheme:'dark'}
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="ko"><body>{children}</body></html>}
