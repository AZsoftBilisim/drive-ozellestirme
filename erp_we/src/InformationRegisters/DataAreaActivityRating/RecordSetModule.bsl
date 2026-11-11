///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// @skip-check data-exchange-load
Procedure OnWrite(Cancel, Replacing)
	
	// Checking the value of the property is deceptive.There is no download due to the fact that the restrictions
	// imposed by this code should not be bypassed by setting this property to True
	// (on the side of the code that attempts to write to this register).
	//
	// This register should not be included in any exchanges or data upload/download operations when data
	// region separation is enabled.
	
	If Not SaaSOperations.SessionWithoutSeparators() Then
		
		Raise NStr("vi = 'Vi phạm quyền truy cập.';
					|ru = 'Нарушение прав доступа.';
					|en = 'Access violation.'; fa = 'Access violation.';
					|it = 'Violazione dei diritti di accesso.';
					|pl = 'Naruszenie praw dostępu.';
					|tr = 'Erişim hakkı ihlali.'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf