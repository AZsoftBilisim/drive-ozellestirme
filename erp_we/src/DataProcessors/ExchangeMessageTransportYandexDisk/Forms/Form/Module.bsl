///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
				|ru = 'Обработка не предназначена для непосредственного использования.';
				|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
				|it = 'L''elaborazione non è destinata all''uso diretto.';
				|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
				|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	
EndProcedure

#EndRegion