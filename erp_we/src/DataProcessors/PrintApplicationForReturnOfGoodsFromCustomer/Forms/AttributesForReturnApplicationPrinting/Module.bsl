
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	PersonsLocalization.AttributesOfPrintingApplicationForRefundProcessTypeOfDocument(ThisObject);
	
	If Not ValueIsFilled(Parameters.DocumentDate) Then // starting processing without the necessary parameters
		WarningText = NStr("vi = 'Không thể mở trực tác bộ xử lý!';
							|ru = 'Обработка не предназначена для интерактивного открытия!';
							|en = 'Data processor is not designed for interactive opening.'; fa = 'Data processor is not designed for interactive opening.';
							|it = 'L''elaborazione non è disponibile per apertura interattiva!';
							|pl = 'Przetwarzanie nie jest przeznaczone dla interaktywnego otwarcia!';
							|tr = 'İşleme interaktif açılış için tasarlanmamıştır!'");
		Raise WarningText;
	Else
		FillPropertyValues(ThisObject, Parameters,,"CloseOnChoice,CloseOnOwnerClose,PurposeUseKey");
		If DocumentDate = Date(1,1,1) Then
			DocumentDate = CurrentSessionDate();
		EndIf;
		
		Items.Customer.ChoiceList.Add(Counterparty, Counterparty);
		
		If Not Counterparty.IsEmpty() Then
			
			CounterpartyIsAnIndividual = (Common.ObjectAttributeValue(Counterparty,"LegalEntityIndividual") = Enums.LegalEntityIndividual.Person);
			FillInDetailsOfCounterpartySDocuments();
			
		EndIf;
	EndIf;
	
	FillInReasonsForReturningSelectionList();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		Cancel = True;
		
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
										|tr = 'Kapatmayın'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Đã thay đổi chi tiết về bản in của đơn trả lại. Đóng mà không lưu chi tiết?';
				|ru = 'Реквизиты печати заявления на возврат были изменены. Закрыть без сохранения реквизитов?';
				|en = 'Return request print details were changed. Close without saving the details?'; fa = 'Return request print details were changed. Close without saving the details?';
				|it = 'I dettagli dell''applicazione di stampa per un rimborso sono stati modificati. Chiudere senza salvare i dettagli?';
				|pl = 'Szczegóły drukowania wniosku o zwrot zostały zmienione. Zamknij bez zapisywania szczegółów?';
				|tr = 'Geri ödeme başvurusunun yazdırma öznitelikleri değiştirildi. Öznitelikleri saklamadan kapat?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "NotClose" Then
		
		SaveParameters = False;
		
	ElsIf UserAnswer = "Close" Then
		
		ForceCloseTheForm = True;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters And Not Exit Then
		
		ParametersStructure = AttributesToChange(ThisObject);
		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DocumentKindOnChange(Item)
	
	If CustomerDocumentKind <> PredefinedValue("Catalog.DocumentKindsOfPersons.EmptyRef") Then
		ArrayOfFoundStrings = IdentityDocumentData.FindRows(New Structure("DocumentKind", CustomerDocumentKind));
		If ArrayOfFoundStrings.Count() > 0 Then
			FillPropertyValues(ThisObject, ArrayOfFoundStrings[0]);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillDocumentViewSelectionList()
	
	DocumentViewCurValue = CustomerDocumentKind;
	
	Items.DocumentKind.ChoiceList.Clear();
	Items.DocumentKind.ChoiceList.Add(Catalogs.DocumentKindsOfPersons.EmptyRef(),"   ");
	
	If ValueIsFilled(Customer) Then
		For Each TableRow In IdentityDocumentData Do
			Items.DocumentKind.ChoiceList.Add(TableRow.DocumentKind, TableRow.Description);
		EndDo;
	EndIf;
	
	If ValueIsFilled(DocumentViewCurValue) Then
		ArrayOfFoundStrings = IdentityDocumentData.FindRows(New Structure("DocumentKind", DocumentViewCurValue));
		If ArrayOfFoundStrings.Count() = 0 Then
			Items.DocumentKind.ChoiceList.Add(DocumentViewCurValue,DocumentViewCurValue);
		EndIf;
	EndIf;
	
	TextOfLastListItem = ?(Items.DocumentKind.ChoiceList.Count() = 1,NStr("vi = 'Chọn dạng chứng từ';
																			|ru = 'Выбрать вид документа';
																			|en = 'Select document kind'; fa = 'Select document kind';
																			|it = 'Seleziona il tipo di documento';
																			|pl = 'Wybierz rodzaj dokumentu';
																			|tr = 'Belge türü seç'"),NStr("vi = 'Chọn dạng chứng từ khác';
																												|ru = 'Выбрать другой вид документа';
																												|en = 'Select another document kind'; fa = 'Select another document kind';
																												|it = 'Seleziona un altro tipo di documento';
																												|pl = 'Wybierz inny rodzaj dokumentu';
																												|tr = 'Diğer belge türü seç'"));
	Items.DocumentKind.ChoiceList.Add(Undefined,TextOfLastListItem);
	
EndProcedure

&AtClient
Procedure DocumentKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = Undefined Then
		StandardProcessing = False;

		OpenForm("Catalog.DocumentKindsOfPersons.ChoiceForm", , ThisObject,,,, New CallbackDescription("DocumentKindChoiceProcessingCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentKindChoiceProcessingCompletion(Result, AdditionalParameters) Export
    
    If Result <> Undefined Then
        CustomerDocumentKind = Result;
        If ValueIsFilled(Customer) Then
            ArrayOfFoundStrings = IdentityDocumentData.FindRows(New Structure("DocumentKind", CustomerDocumentKind));
            If ArrayOfFoundStrings.Count() > 0 Then
                FillPropertyValues(ThisObject, ArrayOfFoundStrings[0]);
            EndIf;
        EndIf;
    EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		
		Cancel = False;
		
		If ValueIsFilled(CustomerDocumentKind) Then
			
			ClearMessages();
			
			ErrorText = "";
			Cancel = Not PersonsClientServerTM.DocumentSeriesIsListedCorrectly(CustomerDocumentKind, CustomerDocumentSeries, ErrorText) Or Cancel;
			If Not IsBlankString(ErrorText) Then
				CommonClientServer.MessageToUser(ErrorText, , "CustomerDocumentSeries");
			EndIf;
			
			ErrorText = "";
			Cancel = Not PersonsClientServerTM.DocumentNumberIsCorrect(CustomerDocumentKind, CustomerDocumentNumber, ErrorText) Or Cancel;
			If Not IsBlankString(ErrorText) Then
				CommonClientServer.MessageToUser(ErrorText, , "CustomerDocumentNumber");
			EndIf;
			
		EndIf;
		
		If Cancel Then
			Return;
		EndIf;
		
		SaveParameters = True;
		If CounterpartyIsAnIndividual Then
			SaveCounterpartyDocumentData();
		EndIf;
		
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Function AttributesToChange(Source)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("CustomerSDateOfBirth",              Source.CustomerSDateOfBirth);
	ParametersStructure.Insert("Customer",                          Source.Customer);
	ParametersStructure.Insert("ReasonForReturn",                     Source.ReasonForReturn);
	ParametersStructure.Insert("CustomerDocumentKind",              Source.CustomerDocumentKind);
	ParametersStructure.Insert("CustomerDocumentSeries",            Source.CustomerDocumentSeries);
	ParametersStructure.Insert("CustomerDocumentNumber",            Source.CustomerDocumentNumber);
	ParametersStructure.Insert("DateOfCustomerDocumentIssue",       Source.DateOfCustomerDocumentIssue);
	ParametersStructure.Insert("CustomerDocumentValidityPeriod",     Source.CustomerDocumentValidityPeriod);
	ParametersStructure.Insert("IssuingAuthorityOfCustomerDocument",          Source.IssuingAuthorityOfCustomerDocument);
	ParametersStructure.Insert("CustomerDocumentBusinessUnitCode", Source.CustomerDocumentBusinessUnitCode);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure FillInDetailsOfCounterpartySDocuments()

	IdentityDocumentData.Clear();
		
	If Counterparty.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentsPersonsSliceLast.DocumentKind,
	|	DocumentsPersonsSliceLast.Series AS CustomerDocumentSeries,
	|	DocumentsPersonsSliceLast.Number AS CustomerDocumentNumber,
	|	DocumentsPersonsSliceLast.DateOfIssue1 AS DateOfCustomerDocumentIssue,
	|	DocumentsPersonsSliceLast.ValidityPeriod AS CustomerDocumentValidityPeriod,
	|	DocumentsPersonsSliceLast.IssuedBy AS IssuingAuthorityOfCustomerDocument,
	|	DocumentsPersonsSliceLast.BusinessUnitCode AS CustomerDocumentBusinessUnitCode,
	|	DocumentKindsOfPersons.Description
	|FROM
	|	InformationRegister.DocumentsPersons.SliceLast(
	|			&DocumentDate,
	|			VALUETYPE(Person) = TYPE(Catalog.Counterparties)
	|				AND Person = &Counterparty
	|				AND ThisIsAnIdentityDocument) AS DocumentsPersonsSliceLast
	|		INNER JOIN Catalog.DocumentKindsOfPersons AS DocumentKindsOfPersons
	|		ON DocumentsPersonsSliceLast.DocumentKind = DocumentKindsOfPersons.Ref
	|
	|ORDER BY
	|	DocumentsPersonsSliceLast.Period DESC";
	
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("DocumentDate", ?(ValueIsFilled(DocumentDate),DocumentDate,CurrentSessionDate()));
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	IdentityDocumentData.Load(Result.Unload());
	FillDocumentViewSelectionList();
EndProcedure

&AtServer
Procedure FillInReasonsForReturningSelectionList()
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	NestedQuery.ReasonForReturn AS ReasonForReturn 
	|FROM (
	|	SELECT
	|		ReturnRequest.ReasonForReturn AS ReasonForReturn
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
	|	WHERE
	|		ReturnRequest.ReasonForReturn <> """"
	|		AND ReturnRequest.Posted
	|		AND &ConditionReturnTable
	|) AS NestedQuery
	|ORDER BY
	|	ReasonForReturn ASC
	|";
	
	TextOfRefundTable = "AND TRUE";
	If AccessRight("Read", Metadata.Documents.ReturnOfGoodsFromCustomer) Then
		
		TextOfRefundTable ="
		|UNION ALL
		|	
		|	SELECT DISTINCT
		|		Return.ReasonForReturn AS ReasonForReturn
		|	FROM
		|		Document.ReturnOfGoodsFromCustomer AS Return
		|	WHERE
		|		Return.ReasonForReturn <> """"
		|		AND Return.Posted";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &ConditionReturnTable", TextOfRefundTable);
	
	Query = New Query(QueryText);
	ReasonsForReturn = Query.Execute().Unload().UnloadColumn("ReasonForReturn");
	Items.ReasonForReturn.ChoiceList.Clear();
	Items.ReasonForReturn.ChoiceList.LoadValues(ReasonsForReturn);
EndProcedure

&AtClient
Procedure SaveCounterpartyDocumentData()
	
	QuestionIsNeeded = False;
	
	If ValueIsFilled(CustomerDocumentKind) And ValueIsFilled(Customer) And Customer = Items.Customer.ChoiceList[0].Presentation Then
		
		ArrayOfFoundStrings = IdentityDocumentData.FindRows(New Structure("DocumentKind", CustomerDocumentKind));
		
		If ArrayOfFoundStrings.Count() > 0 Then
			If ArrayOfFoundStrings[0].CustomerDocumentSeries <> CustomerDocumentSeries Or
				 ArrayOfFoundStrings[0].CustomerDocumentNumber <> CustomerDocumentNumber Or
				 ArrayOfFoundStrings[0].DateOfCustomerDocumentIssue <> DateOfCustomerDocumentIssue Or
				 ArrayOfFoundStrings[0].CustomerDocumentValidityPeriod <> CustomerDocumentValidityPeriod Or
				 ArrayOfFoundStrings[0].IssuingAuthorityOfCustomerDocument <> IssuingAuthorityOfCustomerDocument Or
				 ArrayOfFoundStrings[0].CustomerDocumentBusinessUnitCode <> CustomerDocumentBusinessUnitCode Then
				
				QuestionIsNeeded = True;
			EndIf;
				
		ElsIf ValueIsFilled(CustomerDocumentSeries) Or
				ValueIsFilled(CustomerDocumentNumber) Or
				ValueIsFilled(DateOfCustomerDocumentIssue) Or
				ValueIsFilled(CustomerDocumentValidityPeriod) Or
				ValueIsFilled(IssuingAuthorityOfCustomerDocument) Or
				ValueIsFilled(CustomerDocumentBusinessUnitCode) Then
				
				QuestionIsNeeded = True;
				
		EndIf;
		
		If QuestionIsNeeded Then
			
			ShowQueryBox(
				New CallbackDescription("SaveCounterpartyDocumentDataQuestionCompletion", ThisObject),
				NStr("vi = 'Bạn có muốn ghi lại thông tin về dữ liệu giấy tờ tùy thân?';
					|ru = 'Вы хотите записать информацию о данных документа удостоверяющего личность?';
					|en = 'Do you want to save information about ID document?'; fa = 'Do you want to save information about ID document?';
					|it = 'Vuoi registrare informazioni sui dati di un documento di identità?';
					|pl = 'Chcesz zapisać informacje o danych dokumentu potwierdzającego tożsamość?';
					|tr = 'Tanımlayıcı belgesinin öznitelikleri hakkında bilgi kaydetmek istiyorsunuz?'"),
				QuestionDialogMode.YesNo);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveCounterpartyDocumentDataQuestionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		WriteIdentityDocument();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteIdentityDocument()

	RecordManager = InformationRegisters.DocumentsPersons.CreateRecordManager();
	RecordManager.Period                                   = DocumentDate;
	RecordManager.Person                                  = Counterparty;
	RecordManager.DocumentKind                             = CustomerDocumentKind;
	RecordManager.Series                                    = CustomerDocumentSeries;
	RecordManager.Number                                    = CustomerDocumentNumber;
	RecordManager.DateOfIssue1                               = DateOfCustomerDocumentIssue;
	RecordManager.ValidityPeriod                             = CustomerDocumentValidityPeriod;
	RecordManager.IssuedBy                                 = IssuingAuthorityOfCustomerDocument;
	RecordManager.BusinessUnitCode                         = CustomerDocumentBusinessUnitCode;
	RecordManager.ThisIsAnIdentityDocument = True;
	RecordManager.Write();

EndProcedure

#EndRegion

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
