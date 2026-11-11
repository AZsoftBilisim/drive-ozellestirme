#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Organization = Catalogs.Companies.GetDefaultOrganization();
	RetailStore = Catalogs.Warehouses.DefaultRetailWarehouse();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Print(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Organization) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
												|ru = 'Не заполнено поле ""Организация""';
												|en = 'The ""Company"" field is not filled in'; fa = 'The ""Company"" field is not filled in';
												|it = 'Il campo ""Azienda"" non è stato compilato';
												|pl = 'Nie jest wypełnione pole ""Firma""';
												|tr = '""İş Yeri"" alanı doldurulmadı'"),,"Organization",,Cancel);
	EndIf;
	If Not ValueIsFilled(RetailStore) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Cửa hàng bán lẻ""';
												|ru = 'Не заполнено поле ""Розничный магазин""';
												|en = '""Retail store"" is not filled in'; fa = '""Retail store"" is not filled in';
												|it = 'Il campo ""Negozio al dettaglio"" non è compilato';
												|pl = 'Nie jest wypełnione pole ""Sklep detaliczny""';
												|tr = '""Perakende Mağaza"" alanı doldurulmadı'"),,"RetailStore",,Cancel);
	EndIf;
	
	If Not Cancel Then
		
		ChoiceParameters = New Structure;
		ChoiceParameters.Insert("Organization",      Organization);
		ChoiceParameters.Insert("RetailStore", RetailStore);
		
		Close(ChoiceParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
