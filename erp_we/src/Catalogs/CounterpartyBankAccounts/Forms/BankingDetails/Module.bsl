
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ManualEdit = False;
	InClassifier = False;
	BIC			 = "";
	CorrAccount	 = "";
	Description = "";
	City		 = "";
	Address		 = "";
	Phones	 = "";
	State		 = "";
	
	If Not Parameters.Property("ManualEdit") Then
		Cancel = True;
		Return;
	EndIf;
	
	ManualEdit = Parameters.ManualEdit;
	OwnerAttribute = Parameters.Attribute;
	
	If Parameters.FieldValues.Property("BIC") Then
		BIC	= Parameters.FieldValues.BIC;
	EndIf;
	
	If Parameters.FieldValues.Property("CorrAccount") Then
		CorrAccount = Parameters.FieldValues.CorrAccount;
	EndIf;
	
	If IsBlankString(ManualEdit) Then
		ManualEdit = False;
	EndIf;
	
	If ManualEdit Then
		FillPropertyValues(ThisForm, Parameters.FieldValues,
			"BIC, CorrAccount, Description, City, Address, Phones");
	Else
		Bank = Parameters.Bank;
		If TypeOf(Bank) = Type("CatalogRef.BankClassifier") Then
			Attributes = Common.ObjectsAttributesValues(Bank,
				"Code, CorrAccount, Description, City, Address, Phones, Parent");
			BIC				= Attributes.Code;
			CorrAccount		= Attributes.CorrAccount;
			Description	= Attributes.Description;
			City			= Attributes.City;
			Address			= Attributes.Address;
			Phones		= Attributes.Phones;
			State			= Attributes.Parent;
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
	Close();
	NotifyChoice(GetParameterValues());
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	CloseButtonsClicked = True;
	Close();
	
EndProcedure

#Region AuxiliaryProceduresAndFunctions

&AtServer
Procedure HandleManualChangeFlag()
	
	If ManualEdit Then
		Items.NoteText.Title = NStr("vi = 'Đã ngắt tự động cập nhật phần tử.';
									|ru = 'Автоматическое обновление элемента отключено.';
									|en = 'Automatic update is disabled for this item.'; fa = 'Automatic update is disabled for this item.';
									|it = 'Aggiornamento automatico dell''elemento è disabilitato.';
									|pl = 'Automatyczna aktualizacja elementu jest wyłączona.';
									|tr = 'Otomatik öğe güncellemesi devre dışı bırakıldı.'");
		ReadOnly = False;
	Else
		If InClassifier Then
			Items.NoteText.Title = NStr("vi = 'Phần tử được cập nhật tự động.';
										|ru = 'Элемент обновляется автоматически.';
										|en = 'Automatic update is enabled for this item.'; fa = 'Automatic update is enabled for this item.';
										|it = 'L''elemento si aggiorna automaticamente.';
										|pl = 'Element jest aktualizowany automatycznie.';
										|tr = 'Öğe otomatik olarak güncellenir.'");
			ReadOnly = True;
		Else
			Items.NoteText.Title = NStr("vi = 'Phần tử không tìm thấy trong bảng mã hiệu. Đã tắt tự động cập nhật phần tử.';
										|ru = 'Элемент не найден в классификаторе. Автоматическое обновление элемента отключено.';
										|en = 'Item is not found in the classifier. Automatic update is disabled for this item.'; fa = 'Item is not found in the classifier. Automatic update is disabled for this item.';
										|it = 'L''elemento non è stato trovato nel classificatore. L''aggiornamento automatico dell''elemento è disabilitato.';
										|pl = 'Element nie został znaleziony w klasyfikatorze. Automatyczna aktualizacja elementu jest wyłączona.';
										|tr = 'Sınıflandırıcıda öğe bulunamadı. Otomatik öğe güncellemesi devre dışı bırakıldı.'");
			ReadOnly = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function GetParameterValues()
	
	Result = New Structure;
	Result.Insert("Attribute", OwnerAttribute);
	
	If ManualEdit Then
	    Result.Insert("ManualEdit", ManualEdit);
		FieldValues = New Structure;
		FieldValues.Insert("BIC", BIC);
		FieldValues.Insert("Description", Description);
		FieldValues.Insert("CorrAccount", CorrAccount);
		FieldValues.Insert("City", City);
		FieldValues.Insert("Address", Address);
		FieldValues.Insert("Phones", Phones);
		FieldValues.Insert("ManualEdit", ManualEdit);
		
		Result.Insert("FieldValues", FieldValues);
    Else
		If InClassifier Then
		    Result.Insert("ManualEdit", ManualEdit);
			Result.Insert("Bank", Bank);
		Else 
			Result.Insert("ManualEdit", True);
			FieldValues = New Structure;
			FieldValues.Insert("BIC", BIC);
			FieldValues.Insert("Description", Description);
			FieldValues.Insert("CorrAccount", CorrAccount);
			FieldValues.Insert("City", City);
			FieldValues.Insert("Address", Address);
			FieldValues.Insert("Phones", Phones);
			FieldValues.Insert("ManualEdit", ManualEdit);
			
			Result.Insert("FieldValues", FieldValues);
        EndIf;
	EndIf;
		
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

