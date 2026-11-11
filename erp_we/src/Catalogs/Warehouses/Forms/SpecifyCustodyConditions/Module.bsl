
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	GoodsStorageConditions = Parameters.GoodsStorageConditions;
	SpecialNotes = Parameters.SpecialNotes;
	CustodyWarehouse = Parameters.CustodyWarehouse;
	DepositoryKind = Parameters.DepositoryKind;
	Depository = Parameters.Depository;
	CustodyPeriod = Parameters.CustodyPeriod;
	CustodyUntilCalledFor = Parameters.CustodyUntilCalledFor;
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	
	SetVisibilityAvailabilityOfResponsibleStorageItems(ThisForm);
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters
		And Not Exit Then
	
		ParametersStructure = New Structure();
		ParametersStructure.Insert("GoodsStorageConditions", GoodsStorageConditions);
		ParametersStructure.Insert("SpecialNotes", SpecialNotes);
		ParametersStructure.Insert("CustodyWarehouse", CustodyWarehouse);
		ParametersStructure.Insert("DepositoryKind", DepositoryKind);
		ParametersStructure.Insert("Depository", Depository);
		ParametersStructure.Insert("CustodyPeriod", CustodyPeriod);
		ParametersStructure.Insert("CustodyUntilCalledFor", CustodyUntilCalledFor);
		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ForcefullyCloseTheForm
		And SaveParameters
		And CustodyWarehouse 
		And Not ValueIsFilled(Depository)
		And Not Exit Then
		
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Bên thuê kho"".';
												|ru = 'Поле ""Поклажедержатель"" не заполнено.';
												|en = '""Depository"" is required.'; fa = '""Depository"" is required.';
												|it = 'Il campo ""Titolare"" non è compilato.';
												|pl = 'Nie wypełniono pola ""Posiadacz"".';
												|tr = '""Yük Tutucu"" alanı doldurulmadı.'"),
			,
			"Depository",
			Depository,
			Cancel);
			
	EndIf;
	
	If Not ForcefullyCloseTheForm
		And (Modified And Not SaveParameters) Then
		
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Tùy chỉnh điền các điều kiện lưu kho sẽ bị ngắt.';
								|ru = 'Настройка заполнения условий ответственного хранения будет прервана.';
								|en = 'Configuring population of VMI conditions will be stopped.'; fa = 'Configuring population of VMI conditions will be stopped.';
								|it = 'L''impostazione della compilazione delle condizioni di custodia verrà interrotta.';
								|pl = 'Ustawianie wypełniania warunków depozytu zostanie przerwane.';
								|tr = 'Sorumlu depolama koşullarının doldurulma ayarı kesintiye uğrayacaktır.'");
			Return;
		EndIf;
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatma'"));
		
		AdditionalParameters = New Structure;
		ShowQueryBox(
			New CallbackDescription("ShowQuestionBeforeClosingEnd", ThisObject, AdditionalParameters),
			NStr("vi = 'Các mục tin đã thay đổi. Đóng mà không lưu lại mục tin?';
				|ru = 'Реквизиты были изменены. Закрыть без сохранения реквизитов?';
				|en = 'Details have been changed. Close without saving details?'; fa = 'Details have been changed. Close without saving details?';
				|it = 'I requisiti sono stati modificati. Chiudere senza salvare?';
				|pl = 'Szczegóły zostały zmienione. Zamknij bez zapisywania szczegółów?';
				|tr = 'Öznitelikler değiştirildi. Öznitelikler kaydedilmeden kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuestionBeforeClosingEnd(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "Close" Then
		ForcefullyCloseTheForm = True;
		Close(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DurationOfStorageWhenChanging(Item)
	
	SetVisibilityAvailabilityOfResponsibleStorageItems(ThisForm);
	
EndProcedure

&AtClient
Procedure DepositoryKindOnChange(Item)
	
	SetVisibilityAvailabilityOfResponsibleStorageItems(ThisForm);
	
EndProcedure

&AtClient
Procedure SafekeepingOnChange(Item)
	
	SetVisibilityAvailabilityOfResponsibleStorageItems(ThisForm);
	
EndProcedure

&AtClient
Procedure DepositoryKindClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveParameters = True;
	EndIf;
	
	Close();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailabilityOfResponsibleStorageItems(Form)
	
	If Not Form.UseMultipleCompanies Then
		Form.DepositoryKind = PredefinedValue("Enum.DepositaryKinds.ExternalCounterparty");
	ElsIf Not ValueIsFilled(Form.DepositoryKind) Then
		Form.DepositoryKind = PredefinedValue("Enum.DepositaryKinds.OwnCompany");
	EndIf;
	
	ItemsAvailability = Form.CustodyWarehouse;
	
	Form.Items.DepositoryKind.Enabled = ItemsAvailability And Form.UseMultipleCompanies;
	Form.Items.Depository.Enabled = ItemsAvailability And ValueIsFilled(Form.DepositoryKind);
	Form.Items.CustodyUntilCalledFor.Enabled = ItemsAvailability;
	Form.Items.GoodsStorageConditions.Enabled = ItemsAvailability;
	Form.Items.SpecialNotes.Enabled = ItemsAvailability;
	
	Form.Items.CustodyPeriod.Enabled = ItemsAvailability And Not Form.CustodyUntilCalledFor;
	
	TypesArray = New Array();
	If Form.DepositoryKind = PredefinedValue("Enum.DepositaryKinds.ExternalCounterparty") Then
		TypesArray.Add(Type("CatalogRef.Counterparties"));
	ElsIf Form.DepositoryKind = PredefinedValue("Enum.DepositaryKinds.OwnCompany") Then
		TypesArray.Add(Type("CatalogRef.Companies"));
	EndIf;
	
	DescriptionOfTypesOfBaggageHolder = New TypeDescription(TypesArray);
	Form.Items.Depository.TypeRestriction = DescriptionOfTypesOfBaggageHolder;
	Form.Depository = DescriptionOfTypesOfBaggageHolder.AdjustValue(Form.Depository);
	
EndProcedure

#EndRegion
