#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeOfSelectionObject = Parameters.TypeOfSelectionObject;
	
	If TypeOfSelectionObject = "DMIncomingDocument"
		Or TypeOfSelectionObject = "DMInternalDocument"
		Or TypeOfSelectionObject = "DMOutgoingDocument" Then
		Items.TypePageGroup.CurrentPage = Items.DocumentsGroup;
		WindowOptionsKey = "Document";
	ElsIf TypeOfSelectionObject = "DMCorrespondent" Then
		Items.TypePageGroup.CurrentPage = Items.CounterpartiesGroup;
		WindowOptionsKey = "Counterparty";
	EndIf;
	Items.Folder.Visible = (TypeOfSelectionObject = "DMInternalDocument");
	
	// The parameters can have a preset header.
	If TypeOfSelectionObject = "DMIncomingDocument" Then
		Title = NStr("vi = 'Điều kiện tìm kiếm văn bản đến';
					|ru = 'Условия поиска входящего документа';
					|en = 'Search criteria for incoming document'; fa = 'Search criteria for incoming document';
					|it = 'Condizioni di ricerca del documento in entrata';
					|pl = 'Warunek wyszukiwania dokumentu przychodzącego';
					|tr = 'Gelen belgeyi arama şartı'");
	ElsIf TypeOfSelectionObject = "DMInternalDocument" Then
		Title = NStr("vi = 'Điều kiện tìm kiếm văn bản nội bộ';
					|ru = 'Условия поиска внутреннего документа';
					|en = 'Search criteria for internal document'; fa = 'Search criteria for internal document';
					|it = 'Condizioni di ricerca del documento interno';
					|pl = 'Warunki wyszukiwania dokumentu wewnętrznego';
					|tr = 'Dahili transfer belgesi arama şartı'");
	ElsIf TypeOfSelectionObject = "DMOutgoingDocument" Then
		Title = NStr("vi = 'Điều kiện tìm kiếm văn bản đi';
					|ru = 'Условия поиска исходящего документа';
					|en = 'Search criteria for outgoing document'; fa = 'Search criteria for outgoing document';
					|it = 'Condizioni di ricerca del documento in uscita';
					|pl = 'Warunek wyszukiwania dokumentu wychodzącego';
					|tr = 'Giden belge arama şartı'");
	ElsIf TypeOfSelectionObject = "DMCorrespondent" Then
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			Title = NStr("vi = 'Điều kiện tìm kiếm cơ sở thông tin trao đổi';
						|ru = 'Условия поиска корреспондента';
						|en = 'Correspondent search conditions'; fa = 'Correspondent search conditions';
						|it = 'Condizioni di ricerca del corrispondente';
						|pl = 'Warunki wyszukiwania korespondenta';
						|tr = 'Muhabir arama şartı'");
		Else
			Title = NStr("vi = 'Điều kiện tìm kiếm đối tác';
						|ru = 'Условия поиска контрагента';
						|en = 'Search criteria for counterparty'; fa = 'Search criteria for counterparty';
						|it = 'Condizioni di ricerca della controparte';
						|pl = 'Warunek wyszukiwania kontrahenta';
						|tr = 'Cari hesap arama şartı'");
		EndIf;
	EndIf;
	
	SearchImmediately = False;
	
	// There may be preset conditions in the parameters.
	If Parameters.Property("Filter") And Parameters.Filter <> Undefined Then
		For Each PresetCondition In Parameters.Filter Do
			
			XDTOPropsName = PresetCondition.Key;
			If XDTOPropsName = "correspondent" Then
				FormAttributeName = "Counterparty";
				
			ElsIf XDTOPropsName = "organization" Then
				FormAttributeName = "Organization";
				
			ElsIf XDTOPropsName = "documentType" Then
				FormAttributeName = "DocumentKind";
				
			ElsIf XDTOPropsName = "name" Then
				FormAttributeName = "Description";
				
			ElsIf XDTOPropsName = "sum" Then
				FormAttributeName = "Sum";
				
			ElsIf XDTOPropsName = "regNumber" Then
				FormAttributeName = "RegistrationNumber";
				
			ElsIf XDTOPropsName = "anyDate" Then
				FormAttributeName = "AnyDate";
				
			ElsIf XDTOPropsName = "inn" Then
				FormAttributeName = "TIN";
				
			ElsIf XDTOPropsName = "kpp" Then
				FormAttributeName = "CRTR";
				
			Else
				Continue;
				
			EndIf;
			ConditionDetails = PresetCondition.Value;
			// primitive types can be passed immediately by the value
			If TypeOf(ConditionDetails) = Type("Structure") Then
				If XDTOPropsName = "name" Then
					ConditionValue_ = ConditionDetails.Value;
					If Left(ConditionValue_, 1) = "%" Then
						ConditionValue_ = Mid(ConditionValue_, 2);
					EndIf;
					If Right(ConditionValue_, 1) = "%" Then
						ConditionValue_ = Left(ConditionValue_, StrLen(ConditionValue_) - 1);
					EndIf;
					ThisObject[FormAttributeName] = ConditionValue_;
				Else
					ThisObject[FormAttributeName] = ConditionDetails.Value;
				EndIf;
				If ConditionDetails.Property("ValueID") And ValueIsFilled(ConditionDetails.ValueID) Then
					ThisObject[FormAttributeName + "ID"] = ConditionDetails.ValueID;
				EndIf;
			Else
				ThisObject[FormAttributeName] = ConditionDetails;
			EndIf;
			SearchImmediately = True;
			
		EndDo;
	EndIf;
	
	If Parameters.Property("SearchImmediately") Then
		SearchImmediately = Parameters.SearchImmediately;
	EndIf;
	
	If SearchImmediately Then
		DataProcessors.IntegrationWith1CDocumentManagement.PerformSearchByBankingDetails(TypeOfSelectionObject, FilterStructure1(),
			AddressInTempStorage, NumberOfResults, LimitNumberOfResults);
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not SearchImmediately Or NumberOfResults = 0 Then
		Return;
	EndIf;
	
	AttachIdleHandler("ProcessSearchResults", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

///////////////////////////////////////////////////////////////////////////////////////////////////
// The beginning of the selection

&AtClient
Procedure DocumentKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectingReferencePropsStart("DocumentKind", TypeOfSelectionObject + "Type");
	
EndProcedure

&AtClient
Procedure OrganizationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectingReferencePropsStart("Organization", "DMOrganization");
	
EndProcedure

&AtClient
Procedure CounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectingReferencePropsStart("Counterparty", "DMCorrespondent");
	
EndProcedure

&AtClient
Procedure FolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectingReferencePropsStart("Folder", "DMInternalDocumentFolder");
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Clearing

&AtClient
Procedure DocumentKindClearing(Item, StandardProcessing)
	
	ThisObject[Item.Name + "ID"] = "";
	
EndProcedure

&AtClient
Procedure OrganizationClearing(Item, StandardProcessing)
	
	ThisObject[Item.Name + "ID"] = "";
	
EndProcedure

&AtClient
Procedure CounterpartyClearing(Item, StandardProcessing)
	
	ThisObject[Item.Name + "ID"] = "";
	
EndProcedure

&AtClient
Procedure FolderClearing(Item, StandardProcessing)
	
	ThisObject[Item.Name + "ID"] = "";
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// AutoComplete

&AtClient
Procedure DocumentKindAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			TypeOfSelectionObject + "Type",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMInternalDocumentFolder",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMOrganization",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCorrespondent",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// End of text entry

&AtClient
Procedure DocumentKindTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			TypeOfSelectionObject + "Type", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"DocumentKind", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMInternalDocumentFolder", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Folder", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMOrganization", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Organization", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMCorrespondent", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Counterparty", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// The treatment of choice

&AtClient
Procedure DocumentKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"DocumentKind", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure FolderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Folder", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure OrganizationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Organization", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure CounterpartyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Counterparty", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Other

&AtClient
Procedure DecorationAdvancedSearchClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1());
	FormParameters.Insert("SearchImmediately", False);
	Close();
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearchExtended",
		FormParameters,ThisObject,New UUID,,,
		CallbackDescriptionOnClose,FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToSearch(Command)
	
	PerformServerSearch(TypeOfSelectionObject, AddressInTempStorage,
		NumberOfResults, LimitNumberOfResults);
	ProcessSearchResults();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessSearchResults()
	
	If NumberOfResults = 0 Then
		ShowMessageBox(, NStr("vi = 'Điều kiện tìm kiếm đã đặt không cho kết quả nào.';
								|ru = 'Заданные условия поиска не дали ни одного результата.';
								|en = 'No files found with the specified search criteria.'; fa = 'No files found with the specified search criteria.';
								|it = 'Le condizioni di ricerca fornite non hanno portato alcun risultato.';
								|pl = 'Zadane warunki wyszukiwania nie dały żadnych wyników.';
								|tr = 'Belirtilen arama şartları herhangi bir sonuç getirmedi.'"));
		
	ElsIf LimitNumberOfResults <> 0 Then
		Buttons = New ValueList;
		Buttons.Add(True, StrTemplate(
			NStr("vi = 'Có, hiển thị %1 đầu tiên';
				|ru = 'Да, показать первые %1';
				|en = 'Yes, show first %1'; fa = 'Yes, show first %1';
				|it = 'Si, mostrare i primi %1';
				|pl = 'Tak, pokaż pierwsze %1';
				|tr = 'Evet, önce göster %1'"),
				Format(LimitNumberOfResults, "NG=0")));
		Buttons.Add(False, NStr("vi = 'Không, cần làm rõ điều kiện';
								|ru = 'Нет, уточнить условия';
								|en = 'No, clarify the conditions'; fa = 'No, clarify the conditions';
								|it = 'No, indicare condizioni';
								|pl = 'Nie, uściślij warunki';
								|tr = 'Hayır, şartları kesinleştir'"));
		CallbackDescription = New CallbackDescription("ExecuteSearchCompletion", ThisObject);
		ShowQueryBox(CallbackDescription,
			NStr("vi = 'Điều kiện tìm kiếm đã đặt cho rất nhiều kết quả. Hiển thị kết quả?';
				|ru = 'Заданные условия поиска дали слишком много результатов. Показать результаты?';
				|en = 'Too many search results. Show results?'; fa = 'Too many search results. Show results?';
				|it = 'Le condizioni di ricerca fornite hanno trovato troppi risultati. Mostrare i risultati?';
				|pl = 'Zadane warunki wyszukiwania zwróciły zbyt dużo wyników. Pokazać wyniki?';
				|tr = 'Belirtilen arama şartları çok fazla sonuç getirdi. Sonuçları göster?'"),
			Buttons);
		
	Else
		GoToSearchResults();
		
	EndIf;
	
EndProcedure

// Packages the selection parameters into a structure intended for transmission to the forms to be opened
//
&AtServer
Function FilterStructure1()
	
	// Integration function1sdocumentclientserver.The type representation of the OBJECTXDTO is not used, because
	// synonyms of Attributes on the Form are filled in here, and not Presentations of objects BEFORE.
	
	Filter = New Structure;
	If ValueIsFilled(TrimAll(Description)) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Tên gọi';
											|ru = 'Наименование';
											|en = 'Name'; fa = 'نام';
											|it = 'Nome';
											|pl = 'Name';
											|tr = 'Tanım'"));
		Value.Insert("Value", "%" + TrimAll(Description) + "%");
		Value.Insert("ComparisonOperator", "LIKE");
		Value.Insert("ConditionPresentation", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'có chứa ""%1""';
				|ru = 'содержит ""%1""';
				|en = 'contains ""%1""'; fa = 'contains ""%1""';
				|it = 'contiene ""%1""';
				|pl = 'zawiera ""%1""';
				|tr = '""%1"" içeriyor'"), TrimAll(Description)));
		Filter.Insert("name", Value);
	EndIf;
	If ValueIsFilled(DocumentKindID) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Dạng văn bản';
											|ru = 'Вид документа';
											|en = 'Document kind'; fa = 'نوع سند';
											|it = 'Tipologia di documento';
											|pl = 'Rodzaj dokumentu';
											|tr = 'Belge türü'"));
		Value.Insert("ValueType", TypeOfSelectionObject + "Type");
		Value.Insert("Value", DocumentKind);
		Value.Insert("ValueID", DocumentKindID);
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("documentType", Value);
	EndIf;
	If ValueIsFilled(Sum) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Tổng số';
											|ru = 'Сумма';
											|en = 'Amount'; fa = 'مبلغ';
											|it = 'Importo';
											|pl = 'Amount';
											|tr = 'Tutar'"));
		Value.Insert("Value", Sum);
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("sum", Value);
	EndIf;
	If ValueIsFilled(TrimAll(RegistrationNumber)) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Số đăng ký';
											|ru = 'Рег. №';
											|en = 'Reg. No.'; fa = 'شماره ثبت';
											|it = 'Numero di registrazione №';
											|pl = 'Reg. Nr';
											|tr = 'Kayıt. №'"));
		Value.Insert("Value", TrimAll(RegistrationNumber));
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("regNumber", Value);
	EndIf;
	If ValueIsFilled(AnyDate) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Bắt đầu từ';
											|ru = 'Начиная с';
											|en = 'Starting from'; fa = 'با شروع از';
											|it = 'A decorrere da';
											|pl = 'Zaczynając od';
											|tr = 'Başlangıç'"));
		Value.Insert("Value", AnyDate);
		Value.Insert("ComparisonOperator", ">=");
		Filter.Insert("anyDate", Value);
	EndIf;
	If ValueIsFilled(OrganizationID) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Doanh nghiệp';
											|ru = 'Организация';
											|en = 'Company'; fa = 'Company';
											|it = 'Azienda';
											|pl = 'Firma';
											|tr = 'İş yeri'"));
		Value.Insert("ValueType", "DMOrganization");
		Value.Insert("Value", Organization);
		Value.Insert("ValueID", OrganizationID);
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("organization", Value);
	EndIf;
	If ValueIsFilled(CounterpartyID) Then
		Value = New Structure;
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			Value.Insert("Presentation", NStr("vi = 'Cơ sở thông tin trao đổi';
												|ru = 'Корреспондент';
												|en = 'Correspondent'; fa = 'Correspondent';
												|it = 'Corrispondente';
												|pl = 'Korespondent';
												|tr = 'Muhabir'"));
		Else
			Value.Insert("Presentation", NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Controparte';
												|pl = 'Kontrahent';
												|tr = 'Cari hesap'"));
		EndIf;
		Value.Insert("ValueType", "DMCorrespondent");
		Value.Insert("Value", Counterparty);
		Value.Insert("ValueID", CounterpartyID);
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("correspondent", Value);
	EndIf;
	If ValueIsFilled(FolderID) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Thư mục';
											|ru = 'Папка';
											|en = 'Folder'; fa = 'پوشه';
											|it = 'Cartella';
											|pl = 'Folder';
											|tr = 'Klasör'"));
		Value.Insert("ValueType", "DMInternalDocumentFolder");
		Value.Insert("Value", Folder);
		Value.Insert("ValueID", FolderID);
		Value.Insert("ComparisonOperator", "IN HIERARCHY");
		Filter.Insert("folder", Value);
	EndIf;
	If ValueIsFilled(TrimAll(TIN)) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'MST';
											|ru = 'ИНН';
											|en = 'TIN'; fa = 'شناسه مالیاتی';
											|it = 'Codice Fiscale';
											|pl = 'NIP';
											|tr = 'VKN'"));
		Value.Insert("Value", TrimAll(TIN));
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("inn", Value);
	EndIf;
	If ValueIsFilled(TrimAll(CRTR)) Then
		Value = New Structure;
		Value.Insert("Presentation", NStr("vi = 'Mã chi nhánh';
											|ru = 'КПП';
											|en = 'KPP'; fa = 'KPP';
											|it = 'Codice Causale Di Registrazione Fiscale';
											|pl = 'KPE (Kod Przyczyny wniesienia do Ewidencji)';
											|tr = 'KPP'"));
		Value.Insert("Value", TrimAll(CRTR));
		Value.Insert("ComparisonOperator", "=");
		Filter.Insert("kpp", Value);
	EndIf;
	
	Return Filter;
	
EndFunction

&AtClient
Procedure ExecuteSearchCompletion(Result, Var_Parameters) Export
	
	If Result Then
		GoToSearchResults();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToSearchResults()
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1());
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	Close();
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearchResults",
		FormParameters,ThisObject,New UUID,,,
		CallbackDescriptionOnClose,FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtServer
Procedure PerformServerSearch(TypeOfSelectionObject, AddressInTempStorage, NumberOfResults, LimitNumberOfResults)
	
	DataProcessors.IntegrationWith1CDocumentManagement.PerformSearchByBankingDetails(TypeOfSelectionObject, FilterStructure1(),
		AddressInTempStorage, NumberOfResults, LimitNumberOfResults);
	
EndProcedure

&AtClient
Procedure SelectingReferencePropsStart(Var_AttributeName, Type)
	
	CallbackDescription = New CallbackDescription("SelectingReferencePropsEnds",
		ThisObject, Var_AttributeName);
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", Type);
	
	If Type = "DMCorrespondent" Then // There are potentially a lot of counterparties, you need a choice of search.
		
		Filter = New Structure;
		If ValueIsFilled(TrimAll(Items.Counterparty.EditText)) Then
			Filter.Insert("name", TrimAll(Items.Counterparty.EditText));
			FormParameters.Insert("SearchImmediately", False);
		EndIf;
		FormParameters.Insert("Filter", Filter);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearch",
			FormParameters,
			ThisObject,
			UUID,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
			
	Else // The usual selection from the list.
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
			FormParameters,
			ThisObject,
			New UUID,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingReferencePropsEnds(Result, Var_AttributeName) Export
	
	If Result <> Undefined Then
		ThisObject[Var_AttributeName] = Result.AttributePresentation;
		ThisObject[Var_AttributeName + "ID"] = Result.AttributeID;
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
