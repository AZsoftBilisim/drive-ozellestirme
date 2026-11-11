///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ClientID") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", 
			Common.DefaultLanguageCode());
		
	EndIf;
	
	HTMLField = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=" + Parameters.ClientID +
		"&redirect_uri=http://localhost&access_type=offline&scope=https://www.googleapis.com/auth/drive"
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HTMLFieldDocumentComplete(Item)
	
	Position = StrFind(Item.Document.URL, "code=");
	If Position Then 
		
		Code = Mid(Item.Document.URL, Position + 5);
		
		Close(Code);
		
	EndIf;
	
EndProcedure

#EndRegion
