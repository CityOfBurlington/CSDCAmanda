��U S E   [ A M A N D A _ P r o d u c t i o n ]  
 G O  
 / * * * * * *   O b j e c t :     U s e r D e f i n e d F u n c t i o n   [ d b o ] . [ H t m l E n c o d e ]         S c r i p t   D a t e :   9 / 9 / 2 0 1 3   9 : 4 3 : 3 7   A M   * * * * * * /  
 S E T   A N S I _ N U L L S   O N  
 G O  
 S E T   Q U O T E D _ I D E N T I F I E R   O N  
 G O  
  
 C R E A T E   F U N C T I O N   [ d b o ] . [ H t m l E n c o d e ]  
 (  
         @ U n E n c o d e d   a s   v a r c h a r ( 5 0 0 )  
 )  
 R E T U R N S   v a r c h a r ( 5 0 0 )  
 A S  
 B E G I N  
     D E C L A R E   @ E n c o d e d   a s   v a r c h a r ( 5 0 0 )  
     - - o r d e r   i s   i m p o r t a n t   h e r e .   R e p l a c e   t h e   a m p   f i r s t ,   t h e n   t h e   l t   a n d   g t .    
     - - o t h e r w i s e   t h e   & l t   w i l l   b e c o m e   & a m p ; l t ;    
     S E L E C T   @ E n c o d e d   =    
     R e p l a c e (  
         R e p l a c e ( 		Replace(	 
	             R e p l a c e ( @ U n E n c o d e d , ' & ' , ' & a m p ; ' ) , 	 
	         ' < ' ,   ' & l t ; ' ) , 	 
	     ' > ' ,   ' & g t ; ' ) ,		' ', '&nbsp;')
     R E T U R N   @ E n c o d e d  
 E N D  
  
 G O  
 