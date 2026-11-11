
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// Hide the details disabled by the functional options
	FormAttributes			= GetAttributes();
	UnusedAttributes = Catalogs.Products.BankingDetailsDisabledByFederalDistrict();
	
	For Each Attribute In FormAttributes Do
		If Items.Find(Attribute.Name) = Undefined Then
			Continue;
		EndIf;
		
		If Attribute.Name = "KeepRecordsByCCD" Then
			PropsHeader = NStr("vi = 'Cho phép chỉnh sửa hộp kiểm ""%1""';
								|ru = 'Разрешить редактирование флага ""%1""';
								|en = 'Allow editing the ""%1"" flag'; fa = 'Allow editing the ""%1"" flag';
								|it = 'Consentire la modifica del contrassegno ""%1""';
								|pl = 'Zezwalaj na edycję pola wyboru ""%1""';
								|tr = 'Bayrak düzenlemeye izin ver ""%1""'");
			Items[Attribute.Name].Title = StrTemplate(PropsHeader,
														ProductsLocalization.TittleKeepRecordsOfCCD());
		EndIf;
		
		NameOfProductItemDetails	= Attribute.Name;
		PropsUsed		= UnusedAttributes.Find(NameOfProductItemDetails) = Undefined;
		
		ThisObject[Attribute.Name]				= PropsUsed;
		Items[Attribute.Name].Visible	= PropsUsed;
		
		FormAttributesNames.Add(Attribute.Name, NameOfProductItemDetails);
	EndDo;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	// For all the enabled flags, we will form an array of the corresponding nomenclature details.
	Result = New Array;
	
	For Each Attribute In FormAttributesNames Do
		If ThisObject[Attribute.Value] Then
			Result.Add(Attribute.Presentation);
		EndIf;
	EndDo;
	
	// Some checkboxes manage multiple item details
	If PackagingGroup Then
		Result.Add("UsePackages");
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion
