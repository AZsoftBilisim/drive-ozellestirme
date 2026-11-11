
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Currency = Parameters.Currency;
	Date = Parameters.Date;
	Counterparty = Parameters.Counterparty;
	Organization = Parameters.Organization;
	Partner = Parameters.Partner;
	GoodsAmount = Parameters.GoodsAmount;
	CalledFormID = Parameters.CalledFormID;
	Document = Parameters.Document;
	Posted = Parameters.Posted;
	TheseAreSettlementsWithCustomers = Parameters.TheseAreSettlementsWithCustomers;
	ReadOnly = Parameters.ReadOnly;
	
	PartnerOtherRelations = Parameters.PartnerOtherRelations;
	SelectOnlyUnconditionalDebt = Parameters.SelectOnlyUnconditionalDebt;
	CallerName = Parameters.CallerName;
	
	GetPaymentDecryptionFromVault(Parameters.AddressOfPaymentsInTheStorage);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified Then
		
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
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
				|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
				|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
				|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
				|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
				|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "Close" Then
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	For Each DecryptionString In ARAPDetails Do
		
		If Not ValueIsFilled(DecryptionString.Sum) Then
			
			MessageText = NStr("vi = 'Chưa điền cột ""Số tiền"" tại dòng %LineNumber% của danh sách ""Hạch toán công nợ""';
								|ru = 'Не заполнена колонка ""Сумма"" в строке %LineNumber% списка ""Взаиморасчеты""';
								|en = 'Column ""Amount"" in line %LineNumber% of the ""AR/AP accounting"" list is not filled in'; fa = 'Column ""Amount"" in line %LineNumber% of the ""AR/AP accounting"" list is not filled in';
								|it = 'Colonna ""Importo"" nella riga %LineNumber% dell''elenco ""Взаиморасчеты"" non compilata';
								|pl = 'Nie wypełniono kolumny ""Wartość"" w wierszu %LineNumber% listy ""Rozliczenia wzajemne""';
								|tr = '""Mutabakatlar"" listesinin %LineNumber% satırında ""Tutar"" sütunu doldurulmadı'");
			MessageText = StrReplace(MessageText, "%LineNumber%", DecryptionString.LineNumber);
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				"ARAPDetails["+(DecryptionString.LineNumber-1)+"].Sum",
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	If ARAPDetails.Count() > 0 And GoodsAmount < ARAPDetails.Total("Sum") Then
		MessageText = NStr("vi = 'Số tiền theo các dòng trong phần bảng vượt quá số tiền trong chứng từ %GoodsAmount% %Currency%';
							|ru = 'Сумма по строкам в табличной части превышает сумму документа %GoodsAmount% %Currency%';
							|en = 'Total amount in table rows exceeds document amount %GoodsAmount% %Currency%'; fa = 'Total amount in table rows exceeds document amount %GoodsAmount% %Currency%';
							|it = 'L''importo per righe nella parte tabellare è superiore all''importo del documento %GoodsAmount% %Currency%';
							|pl = 'Wartość wierszy w sekcji tabelarycznej przekracza kwotę dokumentu %GoodsAmount% %Currency%';
							|tr = 'Tablo bölümündeki satırların toplamı, %GoodsAmount% %Currency%belgenin toplamını aşıyor'");
		MessageText = StrReplace(MessageText, "%GoodsAmount%", Format(GoodsAmount, "NFD=2; NZ=0,00"));
		MessageText = StrReplace(MessageText, "%Currency%", Currency);
		CommonClientServer.MessageToUser(
			MessageText,
			,
			"ARAPDetails[0].Sum",
			,
			Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.ARAPObjects.Form.ARAPObjectSelection" Then
		GetPaymentDecryptionFromVault(ValueSelected.AddressOfPaymentsInTheStorage);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPDetails

&AtClient
Procedure ARAPDetailsOnChange(Item)
	
	NumberTable(ARAPDetails);
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If NewRow And Not Copy Then
		
		SumBalance = GoodsAmount - ARAPDetails.Total("Sum");
		TableRow.Sum = SumBalance;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsSumOnChange(Item)

	TableRow = Items.ARAPDetails.CurrentData;
	TableRow.AmountARAP = 0;
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(FormOwner, "ARAPAccounting");
	ParametersStructure = MechanismParameters.ParametersArray[0];
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	RowID = Undefined;
	If FormTable <> Undefined Then 
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Counterparty                = TMCommonUseClientServer.DataAlongWay(FormOwner, ParametersStructure.Counterparty, RowID);
	Organization               = TMCommonUseClientServer.DataAlongWay(FormOwner, ParametersStructure.Organization);
	Currency                    = TMCommonUseClientServer.DataAlongWay(FormOwner, ParametersStructure.DocumentCurrency);
	PaymentType_               = ParametersStructure.PaymentType_;
	PaymentsAsPer275FZ            = TMCommonUseClientServer.DataAlongWay(FormOwner, ParametersStructure.PaymentsAsPer275FZ, , False);
	
	PaymentDecryptionElement = Items.ARAPDetails;
	Sum                     = PaymentDecryptionElement.CurrentData.Sum;
	ARAPObject            = PaymentDecryptionElement.CurrentData.ARAPObject;
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", PaymentType_);
	FilterValues.Insert("Organization", Organization);
	FilterValues.Insert("Counterparty",  Counterparty);
	FilterValues.Insert("PaymentsAsPer275FZ" , PaymentsAsPer275FZ);
	
	If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		FilterValues.Insert("Partner", PredefinedValue("Catalog.Partners.OurEnterprise"));
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectingThePaymentBasis", False);
	SelectionSettings_.Insert("EditableDocument", Document);
	SelectionSettings_.Insert("Currency", Currency);
	SelectionSettings_.Insert("Sum", Sum);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("ReturnStructure", True);
	SelectionSettings_.Insert("SelectAccountsReceivable", PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
	SelectionSettings_.Insert("CurrentValue", ARAPObject);
	
	OpenForm("Catalog.ARAPObjects.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Items.ARAPDetails.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPCurrencyOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	TableRow.AmountARAP = 0;
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(FormOwner, FormOwner.Items.ReducedDebtByLine, Text, ChoiceData, StandardProcessing,, True);
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(FormOwner, FormOwner.Items.ReducedDebtByLine, Text, ChoiceData, StandardProcessing,, True);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure CacheParameters(MechanismParameters)
	
	VT = ARAPDetails.Unload();
	AddressPaymentDecryption = PutToTempStorage(VT, New UUID());
	
	For Each ParametersStructure In MechanismParameters.ParametersArray Do
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
			ParametersStructure.AddressPaymentDecryption = AddressPaymentDecryption;
			ParametersStructure.Ref = Document;
			ParametersStructure.Counterparty = Counterparty;
			ParametersStructure.Organization = Organization;
			ParametersStructure.DocumentCurrency = Currency;
			ParametersStructure.DocumentAmount = GoodsAmount;
			ParametersStructure.Date = Date;
			ParametersStructure.PaymentID = "";
			ParametersStructure.PaymentType_ = ?(TypeOf(Document)=Type("DocumentRef.ReturnOfGoodsFromCustomer"),
												Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting,
												Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
		EndIf;
	EndDo;
	
	TMCommonUse.SaveEngineDataToFormCache(ThisForm, "ARAPAccounting", MechanismParameters);
EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(FormOwner, "ARAPAccounting");
	CacheParameters(MechanismParameters);
	
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, CallerName);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		ForceCloseTheForm = True;
		Close(PlacePaymentDecryptionInVault());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetPaymentDecryptionFromVault(AddressOfPaymentsInTheStorage)
	
	ARAPDetails.Clear();
	
	TempTable = GetFromTempStorage(AddressOfPaymentsInTheStorage);
	
	For Each DecryptionString In TempTable Do
		NewRow = ARAPDetails.Add();
		FillPropertyValues(NewRow, DecryptionString);
	EndDo;
	
	NumberTable(ARAPDetails);
	
EndProcedure

&AtServer
Function PlacePaymentDecryptionInVault()
	
	TempTable = ARAPDetails.Unload(,"ARAPObject, Sum, ARAPCurrency, AmountARAP");
	CompensationAmount = GoodsAmount - ARAPDetails.Total("Sum");
	If CompensationAmount > 0 Then
		NewRow = TempTable.Add();
		NewRow.Sum = CompensationAmount;
	EndIf;
	
	Return PutToTempStorage(TempTable, CalledFormID);
	
EndFunction

&AtClientAtServerNoContext
Procedure NumberTable(ARAPDetails)
	
	LineNumber = 1;
	For Each DecryptionString In ARAPDetails Do
		DecryptionString.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
EndProcedure

#EndRegion
