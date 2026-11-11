#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public



#EndRegion

#Region Private


#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
			|vi = 'Invalid object call on the client.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf