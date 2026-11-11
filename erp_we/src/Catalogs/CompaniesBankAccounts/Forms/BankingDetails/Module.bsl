
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.Property("ManualEdit") Then
		Cancel = True;
		Return;
	EndIf;
	
	ManualEdit = False;
	InClassifier = False;
	
	ManualEdit = Parameters.ManualEdit;
	OwnerAttribute = Parameters.Attribute;
	
	If Parameters.FieldValues.Property("BIC") Then
		BIC = Parameters.FieldValues.BIC;
	EndIf;
	If Parameters.FieldValues.Property("SWIFT") Then
		SWIFTBIC = Parameters.FieldValues.SWIFT;
	EndIf;
	
	If Parameters.FieldValues.Property("CorrAccount") Then
		CorrAccount = Parameters.FieldValues.CorrAccount;
	EndIf;
	
	If ManualEdit Then
		FillPropertyValues(ThisForm, Parameters.FieldValues);
	Else
		Bank = Parameters.Bank;
		If TypeOf(Bank) = Type("CatalogRef.BankClassifier") Then
			
			BankingDetails = Common.ObjectAttributesValues(Bank,
				"Code, SWIFTBIC, CorrAccount, Description, InternationalDescription,
				|Country, City, CityInternationalFormat, Address, InternationalAddress, Phones, Parent");
			
			FillPropertyValues(ThisForm, BankingDetails);
			BIC                       = BankingDetails.Code;
			State                    = BankingDetails.Parent;
			DescriptionInternational = BankingDetails.InternationalDescription;
			InClassifier = True;
		EndIf;
	EndIf;
	
	HandleManualChangeFlag();
	CloseButtonsClicked = False;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure OkCommand(Command)
	
	CloseButtonsClicked = True;
	ParameterValues = GetParameterValues();
	Close(ParameterValues);
	NotifyChoice(ParameterValues);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	CloseButtonsClicked = True;
	Close();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

Procedure HandleManualChangeFlag()
	
	If ManualEdit Then
		Items.NoteText.Title = NStr("vi = 'Đã ngắt tự động cập nhật phần tử';
									|ru = 'Автоматическое обновление элемента отключено';
									|en = 'Automatic update is disabled for this item'; fa = 'Automatic update is disabled for this item';
									|it = 'Aggiornamento automatico dell''elemento è disabilitato';
									|pl = 'Automatyczna aktualizacja elementu jest odrzucona';
									|tr = 'Otomatik öğe güncellemesi devre dışı bırakıldı'");
		ReadOnly = False;
	Else
		If InClassifier Then
			Items.NoteText.Title = NStr("vi = 'Phần tử đang được cập nhật tự động';
										|ru = 'Элемент обновляется автоматически';
										|en = 'Automatic update is enabled for this item'; fa = 'Automatic update is enabled for this item';
										|it = 'L''elemento si aggiorna automaticamente';
										|pl = 'Element jest aktualizowany automatycznie';
										|tr = 'Öğe otomatik olarak güncellenir'");
			ReadOnly = True;
		Else
			Items.NoteText.Title = NStr("vi = 'Không tìm thấy trong bảng mã hiệu, đã ngắt tự động cập nhật phần tử';
										|ru = 'Элемент не найден в классификаторе, автоматическое обновление элемента отключено';
										|en = 'Item is not found in the classifier. Automatic update is disabled for this item'; fa = 'Item is not found in the classifier. Automatic update is disabled for this item';
										|it = 'L''elemento non è stato trovato nel classificatore, l''aggiornamento automatico dell''elemento è disabilitato';
										|pl = 'Element nie został znaleziony w klasyfikatorze, automatyczna aktualizacja elementu jest odrzucona';
										|tr = 'Sınıflandırıcıda öğe bulunamadı, otomatik öğe güncellemesi devre dışı bırakıldı'");
			ReadOnly = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function GetParameterValues()
	
	Result = New Structure;
	Result.Insert("Attribute", OwnerAttribute);
	
	If ManualEdit Then
		
		FieldValues = FieldsStructure();
		FillPropertyValues(FieldValues, ThisForm);
		FieldValues.Insert("ManualEdit", ManualEdit);
		
		Result.Insert("ManualEdit", ManualEdit);
		Result.Insert("FieldValues", FieldValues);
	Else
		If InClassifier Then
			Result.Insert("ManualEdit", ManualEdit);
			Result.Insert("Bank", Bank);
		Else
			FieldValues = FieldsStructure();
			FillPropertyValues(FieldValues, ThisForm);
			
			Result.Insert("FieldValues", FieldValues);
			Result.Insert("ManualEdit", True);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function FieldsStructure()
	
	FieldsStructure = New Structure;
	FieldsStructure.Insert("BIC", "");
	FieldsStructure.Insert("SWIFTBIC", "");
	FieldsStructure.Insert("CorrAccount", "");
	FieldsStructure.Insert("Description", "");
	FieldsStructure.Insert("DescriptionInternational", "");
	FieldsStructure.Insert("Country", Undefined);
	FieldsStructure.Insert("City", "");
	FieldsStructure.Insert("CityInternationalFormat", "");
	FieldsStructure.Insert("State", "");
	FieldsStructure.Insert("RegionCode", "");
	FieldsStructure.Insert("Address", "");
	FieldsStructure.Insert("InternationalAddress", "");
	FieldsStructure.Insert("Phones", "");
	
	Return FieldsStructure;
	
EndFunction

#EndRegion