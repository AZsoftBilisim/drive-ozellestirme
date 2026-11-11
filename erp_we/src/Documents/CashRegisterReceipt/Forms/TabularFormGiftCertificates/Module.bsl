
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	OpeningModeSurcharge = Parameters.OpeningModeSurcharge;
	PayInAddition = Parameters.PayInAddition;
	Currency = Parameters.Currency;
	Organization = Parameters.Organization;
	AddressInStorageGoods = Parameters.AddressInStorageGoods;
	SupportedPeripheralTypes	= "BarcodeScanner,MagneticStripeCardReaders";
	
	ParametersForProcessingGiftCertificates = GiftCertificatesServerCall.ParametersForProcessingReceivedCode();
	// By default, we use the previous selection, if another one is passed, then we use it.
	If Not Parameters.Property("Filter", ParametersForProcessingGiftCertificates.Filters) Then
		ParametersForProcessingGiftCertificates.Filters = New Structure;
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
		FilterArray.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
		
		ParametersForProcessingGiftCertificates.Filters.Insert("Status", FilterArray);	
	EndIf;
	
	If Not Parameters.Property("RegisterNewOnes", ParametersForProcessingGiftCertificates.RegisterNewOnes) Then
		ParametersForProcessingGiftCertificates.RegisterNewOnes = False;
	EndIf;
		
	UseCurDateOfSession = True;
	CurrentDate = CurrentSessionDate();
	If ParametersForProcessingGiftCertificates.Filters.Property("Date") 
		And ValueIsFilled(ParametersForProcessingGiftCertificates.Filters.Date) Then
		UseCurDateOfSession = False;
		CurrentDate = ParametersForProcessingGiftCertificates.Filters.Date;
	EndIf;
		
	GiftCertificateSelectionParameters = New Array;
	For Each FilterElement In ParametersForProcessingGiftCertificates.Filters Do
		GiftCertificateSelectionParameters.Add(New ChoiceParameter(FilterElement.Key, FilterElement.Value));
	EndDo;
	Items.GiftCertificatesGiftCertificate.ChoiceParameters = New FixedArray(GiftCertificateSelectionParameters);
	
	ShowResultItRemainsToPayExtra = True;
	If Parameters.Property("ShowResultItRemainsToPayExtra", ShowResultItRemainsToPayExtra) 
		And Not ShowResultItRemainsToPayExtra Then
		Items.ItRemainsToPayExtra.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.AddressInStorage) Then
		TableGiftCertificates = GetFromTempStorage(Parameters.AddressInStorage); // ValueTable
		TMCommonUse.NumberValueTable(TableGiftCertificates, "IndexOf");
		TableGiftCertificates.Columns.Add("Balance", TMCommonUse.MoneyFieldTypeDescription());
		
		Query = New Query("SELECT
		|	CAST(TableGiftCertificates.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate,
		|	TableGiftCertificates.IndexOf AS IndexOf
		|INTO TableGiftCertificatesOriginal
		|FROM
		|	&TableGiftCertificates AS TableGiftCertificates
		|;
		|
		|SELECT
		|	TableGiftCertificates.GiftCertificate AS GiftCertificate,
		|	TableGiftCertificates.IndexOf AS IndexOf,
		|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
		|	ISNULL(ARAPObjects.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
		|	TableGiftCertificates.GiftCertificate.Owner.GiftCardAccounting25 AS GiftCardAccounting25,
		|	TableGiftCertificates.GiftCertificate.Owner.PartialPayment AS PartialPayment,
		|
		|	ISNULL(ActivatingGiftCertificates.ValidityStartDate, DATETIME(1, 1, 1)) AS ValidityStartDate,
		|	ISNULL(ActivatingGiftCertificates.ValidityEndDate, DATETIME(1, 1, 1)) AS ValidityEndDate,
		|	ISNULL(ActivatingGiftCertificates.Active, FALSE) AS ActivationStatus,
		|	(CASE
		|		WHEN &Currency <> TableGiftCertificates.GiftCertificate.Owner.Currency
		|			THEN CASE
		|					WHEN ISNULL(CurrencyExchangeRatesCertificates.CourseDenominator, 0) > 0
		|						AND ISNULL(CurrencyExchangeRatesCertificates.CourseNumerator, 0) > 0
		|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
		|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
		|					THEN 
		|						(CurrencyExchangeRatesCertificates.CourseNumerator * Currency_Rates.CourseDenominator)
		|						/ (Currency_Rates.CourseNumerator * CurrencyExchangeRatesCertificates.CourseDenominator)
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END) AS ConversionRate_1
		|INTO TableGiftCertificates
		|FROM
		|	TableGiftCertificatesOriginal AS TableGiftCertificates
		|	
		|	LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
		|	ON TableGiftCertificates.GiftCertificate = ActivatingGiftCertificates.GiftCertificate
		|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|	ON (ARAPObjects.Object = TableGiftCertificates.GiftCertificate)
		|		AND NOT ARAPObjects.DeletionMark
		|	
		|	// Let's determine the currency exchange rate of the document.
		|	LEFT JOIN
		|		InformationRegister.RelativeExchangeRates.SliceLast(&BorderDateEndOfDay, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
		|	ON
		|		TRUE
		|		
		|	// Let's determine the exchange rate of mutual settlements.
		|	LEFT JOIN
		|		InformationRegister.RelativeExchangeRates.SliceLast(&BorderDateEndOfDay, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRatesCertificates
		|	ON
		|		TableGiftCertificates.GiftCertificate.Owner.Currency = CurrencyExchangeRatesCertificates.Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GiftCertificatesBalance.GiftCertificate AS GiftCertificate,
		|	GiftCertificatesBalance.SumBalance AS Balance
		|INTO GiftCertificateBalances
		|FROM
		|	AccumulationRegister.GiftCertificates.Balance(, GiftCertificate IN 
		|															(SELECT T.GiftCertificate FROM TableGiftCertificates AS T 
		|															 WHERE NOT T.GiftCardAccounting25)) AS GiftCertificatesBalance
		|UNION ALL
		|
		|SELECT
		|	CustomersARAPAccountingBalance.ARAPObject.Object AS GiftCertificate,
		|	(CASE WHEN CustomersARAPAccountingBalance.SumBalance < 0 THEN
		|		-CustomersARAPAccountingBalance.SumBalance
		|		ELSE CustomersARAPAccountingBalance.SumBalance
		|	  END) AS Balance
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject IN 
		|														(SELECT T.ARAPObject FROM TableGiftCertificates AS T 
		|													 	 WHERE T.GiftCardAccounting25 
		|													  	  AND NOT T.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef))) AS CustomersARAPAccountingBalance
		|;
		|		
		|////////////////////////////////////////////////////////////////////////////////		
		|	
		|SELECT
		|	TableGiftCertificates.GiftCertificate AS GiftCertificate,
		|	TableGiftCertificates.IndexOf AS IndexOf,
		|	TableGiftCertificates.ARAPObject AS ARAPObject,
		|	TableGiftCertificates.Partner AS Partner,
		|	TableGiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
		|	TableGiftCertificates.PartialPayment AS PartialPayment,
		|	TableGiftCertificates.ValidityStartDate AS ValidityStartDate,
		|	TableGiftCertificates.ValidityEndDate AS ValidityEndDate,
		|	TableGiftCertificates.ActivationStatus AS ActivationStatus,
		|	ISNULL(GiftCertificateBalances.Balance, 0)
		|	* TableGiftCertificates.ConversionRate_1 AS Balance
		|FROM
		|	TableGiftCertificates AS TableGiftCertificates
		|	
		|	LEFT JOIN GiftCertificateBalances AS GiftCertificateBalances
		|		ON GiftCertificateBalances.GiftCertificate = TableGiftCertificates.GiftCertificate
		|
		|ORDER BY
		|	TableGiftCertificates.IndexOf
		|;
		|");
		
		Query.Parameters.Insert("TableGiftCertificates", TableGiftCertificates);
		CurrentSessionDate = CurrentDate;
		If UseCurDateOfSession Then
			CurrentSessionDate = CurrentSessionDate();
		EndIf;		
		Query.SetParameter("Date", CurrentSessionDate);
		Query.SetParameter("BorderDateEndOfDay", New Boundary(EndOfDay(CurrentSessionDate), BoundaryType.Including));
		Query.SetParameter("Currency", Currency);
		Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
		Query.SetParameter("Organization", Organization);
		
		GiftCertificates.Load(TableGiftCertificates);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		While Selection.Next() Do
			
			TableRows = GiftCertificates.FindRows(New Structure("IndexOf",Selection.IndexOf));
			If TableRows.Count() > 0 Then
				FillPropertyValues(TableRows[0], Selection, ,"IndexOf");
			EndIf;
			
		EndDo;
		
		If Parameters.Property("CurrentRowIndex") Then
			CurrentRowIndex = Parameters.CurrentRowIndex;
			If Not CurrentRowIndex = Undefined Then
				Items.GiftCertificates.CurrentRow = GiftCertificates[CurrentRowIndex].GetID();
			EndIf;
		EndIf;
		
	EndIf;

	PayAmount = 0;
	For Each TSRow In GiftCertificates Do
		PayAmount = PayAmount + TSRow.Sum;
	EndDo;
	
	If OpeningModeSurcharge And PayInAddition > 0 Then
		ItRemainsToPayExtra = PayInAddition;
	EndIf;
	
	Items.GiftCertificatesGiftCertificateOwnerNominal.Title = Items.GiftCertificatesGiftCertificateOwnerNominal.Title + " " + "(" + Currency + ")";
	Items.GiftCertificatesSum.Title   = Items.GiftCertificatesSum.Title + " " + "(" + Currency + ")";
	Items.GiftCertificatesBalance.Title = Items.GiftCertificatesBalance.Title + " " + "(" + Currency + ")";
	Items.GroupInTotal.Title = Items.GroupInTotal.Title + " " + "(" + Currency + ")";

	Items.GiftCertificatesConsiderAGiftCertificate.Enabled = (Not OpeningModeSurcharge Or ItRemainsToPayExtra > 0);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, SupportedPeripheralTypes);
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ClearMessages();
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ClearMessages();
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ClearMessages();
		ProcessGiftCertificate(Parameter.GiftCertificate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGiftCertificates

&AtClient
Procedure GiftCertificatesSumOnChange(Item)
	
	CurrentRow = Items.GiftCertificates.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	// If there was nothing to pay extra, then the entered amount should be less than
	// the largest amount from the amount before the change and the amount that remains to be paid.
	If OpeningModeSurcharge And PayInAddition = 0 Then
		AmountBeforeChange = PayAmount - (GiftCertificates.Total("Sum") - CurrentRow.Sum);
		CurrentRow.Sum = Min(CurrentRow.Sum, AmountBeforeChange + ItRemainsToPayExtra);
	EndIf;
	
	CurrentRow.Sum = Min(CurrentRow.Sum, CurrentRow.Balance);
	AmountOfPaymentByGiftCertificates = GiftCertificates.Total("Sum");
	
	If OpeningModeSurcharge Then
		DeltaOfPaymentAmount = PayAmount - AmountOfPaymentByGiftCertificates;
		ItRemainsToPayExtra = ItRemainsToPayExtra + DeltaOfPaymentAmount;
	EndIf;

	// new payment amount
	PayAmount = AmountOfPaymentByGiftCertificates;
	
	// If, as a result of the interactive input, an overpayment came out and if you had to pay something extra,
	// then you need to reduce the amount in the line and the amount of payment
	If OpeningModeSurcharge And ItRemainsToPayExtra < 0 And PayInAddition <> 0 Then
		CurrentRow.Sum = CurrentRow.Sum + ItRemainsToPayExtra;
		PayAmount = PayAmount + ItRemainsToPayExtra;
		ItRemainsToPayExtra = 0;
	EndIf;
	
	Items.GiftCertificatesConsiderAGiftCertificate.Enabled = (Not OpeningModeSurcharge Or ItRemainsToPayExtra > 0);
	
EndProcedure

&AtClient
Procedure GiftCertificatesBeforeDeleteRow(Item, Cancel)
	
	DataToDelete_1 = Items.GiftCertificates.CurrentData;
	DeltaChanges = DataToDelete_1.Sum;
	PayAmount = PayAmount - DeltaChanges;
	
	If OpeningModeSurcharge Then
		ItRemainsToPayExtra = ItRemainsToPayExtra + DeltaChanges;
	EndIf;
EndProcedure

&AtClient
Procedure GiftCertificatesAfterDeleteRow(Item)
	
	If GiftCertificates.Count() Then
		For Each StringOfGiftCertificates In GiftCertificates.FindRows(New Structure("PartialPayment",False)) Do
			ProcessGiftCertificate(StringOfGiftCertificates.GiftCertificate);
		EndDo;
		
		For Each StringOfGiftCertificates In GiftCertificates.FindRows(New Structure("PartialPayment",True)) Do
			ProcessGiftCertificate(StringOfGiftCertificates.GiftCertificate);
		EndDo;
	Else
		Items.GiftCertificatesConsiderAGiftCertificate.Enabled = (Not OpeningModeSurcharge Or ItRemainsToPayExtra > 0);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	CheckPaymentBySegment(Cancel);
	
	CheckDuplicatesOfRowsInTablePart(Cancel);
	
	For Each TSRow In GiftCertificates Do
		
		If TSRow.Balance < TSRow.Sum And TSRow.Sum > 0 Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số tiền thanh toán vượt quá số dư vốn bằng tiền trên chứng thư ""%1"" trong dòng %2';
						|ru = 'Сумма оплаты превышает остаток денежных средств на сертификате ""%1"" в строке %2';
						|en = 'The payment amount exceeds the balance on certificate ""%1"" in line %2'; fa = 'The payment amount exceeds the balance on certificate ""%1"" in line %2';
						|it = 'La somma dei pagamenti supera il saldo contabile nel certificato ""%1"" nella riga %2';
						|pl = 'Wartość płatności przekracza saldo środków pieniężnych na certyfikacie ""%1"" w wierszu %2';
						|tr = 'Ödeme tutarı %2 satırdaki ""%1"" sertifikasının nakit bakiyesini aşıyor'"),
					TSRow.GiftCertificate, GiftCertificates.IndexOf(TSRow) + 1),
				Undefined,
				,
				,
				Cancel);
		EndIf;
		
		If TSRow.Sum = 0 Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền trường ""Số tiền"" tại dòng %1';
						|ru = 'Не заполнено поле ""Сумма"" в строке %1';
						|en = '""Amount"" in line %1 is not filled in'; fa = '""Amount"" in line %1 is not filled in';
						|it = 'Il campo ""Somma"" nella riga non è compilato %1';
						|pl = 'Nie wypełniono pola ""Wartość"" w wierszu %1';
						|tr = '%1 satırındaki ""Tutar"" alanı doldurulmamış'"),
					GiftCertificates.IndexOf(TSRow) + 1),
				Undefined,
				,
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(TSRow.GiftCertificate) Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền trường ""Phiếu quà tặng"" tại dòng %1';
						|ru = 'Не заполнено поле ""Подарочный сертификат"" в строке %1';
						|en = '""Gift card"" in line %1 is not filled in'; fa = '""Gift card"" in line %1 is not filled in';
						|it = 'Il campo ""Buono regalo"" nella riga non è compilato %1';
						|pl = 'Nie wypełniono pola ""Certyfikat podarunkowy"" w wierszu %1';
						|tr = '%1 satırındaki ""Hediye kartı"" alanı doldurulmamış'"),
					GiftCertificates.IndexOf(TSRow) + 1),
				Undefined,
				"GiftCertificates["+GiftCertificates.IndexOf(TSRow)+"].GiftCertificate",
				,
				Cancel);
		EndIf;

		If TSRow.ActivationStatus = True
			And TSRow.ValidityEndDate < CurrentDate And ValueIsFilled(TSRow.GiftCertificate) Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Phiếu quà tặng tại dòng %1 đã quá hạn. Ngày kết thúc hiệu lực %2.';
						|ru = 'Подарочный сертификат в строке %1 просрочен. Дата окончания действия %2.';
						|en = 'Gift card in line %1 has overdue. Validity expiration date %2.'; fa = 'Gift card in line %1 has overdue. Validity expiration date %2.';
						|it = 'Il buono regalo nella riga %1 è scaduto. Data validità %2.';
						|pl = 'Certyfikat podarunkowy w wierszu %1 jest nieważny. Data wygaśnięcia %2.';
						|tr = '%1 satırdaki hediye kartının son kullanma tarihi geçmiştir. Son kullanma tarihi %2'"),
					GiftCertificates.IndexOf(TSRow) + 1, Format(TSRow.ValidityEndDate, "DLF=D")),
				Undefined,
				"GiftCertificates["+GiftCertificates.IndexOf(TSRow)+"].GiftCertificate",
				,
				Cancel);
		EndIf;
	
		If ValueIsFilled(TSRow.GiftCertificate)
				And (Not TSRow.ActivationStatus Or TSRow.Balance <= 0) Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể sử dụng phiếu quà tặng trong dòng %1 để thanh toán.';
						|ru = 'Подарочный сертификат в строке %1 не может быть использован для оплаты.';
						|en = 'You cannot use the gift card in row %1 for payment.'; fa = 'You cannot use the gift card in row %1 for payment.';
						|it = 'Il buono regalo nella stringa %1 non può essere utilizzato per il pagamento.';
						|pl = 'Certyfikat podarunkowy w wierszu %1 nie może być użyty do zapłaty.';
						|tr = '%1 satırdaki hediye kartı ödeme için kullanılamıyor.'"),
					GiftCertificates.IndexOf(TSRow) + 1),
				Undefined,
				"GiftCertificates["+GiftCertificates.IndexOf(TSRow)+"].GiftCertificate",
				,
				Cancel);
		EndIf;
		
	EndDo;

	If Not Cancel Then
		Close(PutTabularPartGiftCertificatesInStorage(FormOwner.UUID));
	EndIf;
	
EndProcedure

&AtClient
Procedure ConsiderAGiftCertificate(Command)
	
	ClearMessages();

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DoNotUseManualInput", False);
	AdditionalParameters.Insert("Filter", ParametersForProcessingGiftCertificates.Filters);
	AdditionalParameters.Insert("RegisterNewOnes", ParametersForProcessingGiftCertificates.RegisterNewOnes);
	
	OpenForm(
		"Catalog.GiftCertificates.Form.ReadGiftCard",
		AdditionalParameters,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GiftCertificates.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.ActivationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.ValidityEndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("CurrentDate");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GiftCertificatesSum.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.ActivationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.ValidityEndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("CurrentDate");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GiftCertificates.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	GiftCertificatesClient.ProcessReceivedCodeOnClient(
		ThisObject,
		ArrayOfBarcodes[0].Barcode,
		PredefinedValue("Enum.CardCodeTypes.Barcode"),
		ParametersForProcessingGiftCertificates);
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	GiftCertificatesClient.ProcessReceivedCodeOnClient(
		ThisObject,
		Data,
		PredefinedValue("Enum.CardCodeTypes.MagneticCode"),
		ParametersForProcessingGiftCertificates);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function PutTabularPartGiftCertificatesInStorage(Id)
	
	Return PutToTempStorage(GiftCertificates.Unload(), Id);
	
EndFunction

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate, RowID = Undefined)
	
	Query = New Query(
	"SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	GiftCertificates.Owner.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.Owner.PartialPayment AS PartialPayment,
	|	CASE
	|		WHEN &Currency <> GiftCertificates.Owner.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyExchangeRatesCertificates.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyExchangeRatesCertificates.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyExchangeRatesCertificates.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyExchangeRatesCertificates.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS ConversionRate_1,
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,	
	|	ISNULL(ARAPObjects.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,	
	|	ISNULL(GiftCardHistory.Status, VALUE(Enum.GiftCertificateStatuses.NotActivated)) AS StatusFromHistoryOfGiftCertificates,	
	|	ISNULL(ActivatingGiftCertificates.Active, FALSE) AS ActivationStatus,
	|	ISNULL(ActivatingGiftCertificates.ValidityStartDate, DATETIME(1, 1, 1)) AS ValidityStartDate,
	|	ISNULL(ActivatingGiftCertificates.ValidityEndDate, DATETIME(1, 1, 1)) AS ValidityEndDate
	|INTO TableGiftCertificates
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|	
	|LEFT JOIN
	|	InformationRegister.RelativeExchangeRates.SliceLast(&BorderDateEndOfDay, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRatesCertificates
	|ON 
	|	GiftCertificates.Owner.Currency = CurrencyExchangeRatesCertificates.Currency
	|	AND GiftCertificates.Ref = &Ref
	|	
	|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&BorderDateEndOfDay, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|	
	|LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|ON (ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref)
	|
	|LEFT JOIN InformationRegister.GiftCardHistory.SliceLast(&BorderDateEndOfDay, GiftCertificate = &Ref) AS GiftCardHistory
	|	ON GiftCardHistory.GiftCertificate = GiftCertificates.Ref
	|
	|LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|	ON (ARAPObjects.Object = GiftCertificates.Ref)
	|		AND NOT ARAPObjects.DeletionMark
	|	
	|WHERE
	|	GiftCertificates.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////
	|SELECT 
	|	GiftCertificatesBalance.GiftCertificate AS GiftCertificate,
	|	GiftCertificatesBalance.SumBalance AS SumBalance
	|INTO GiftCertificatesBalance
	|FROM
	|	AccumulationRegister.GiftCertificates.Balance(&BorderDateEndOfDay, 
	|													GiftCertificate IN (SELECT T.GiftCertificate 
	|																			FROM TableGiftCertificates AS T 
	|																			WHERE NOT T.GiftCardAccounting25)) AS GiftCertificatesBalance
	|UNION ALL
	|
	|SELECT 
	|	CustomersARAPAccountingBalance.ARAPObject.Object AS GiftCertificate,
	|	(CASE WHEN CustomersARAPAccountingBalance.SumBalance < 0
	|		THEN -CustomersARAPAccountingBalance.SumBalance
	|		ELSE CustomersARAPAccountingBalance.SumBalance
	|	END) AS SumBalance	
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(&BorderDateEndOfDay, 
	|												ARAPObject IN (SELECT T.ARAPObject 
	|												FROM TableGiftCertificates AS T 
	|												WHERE T.GiftCardAccounting25 
	|													AND NOT T.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef))) AS CustomersARAPAccountingBalance
	|;
	|
	|SELECT
	|	GiftCertificates.ARAPObject AS ARAPObject,
	|	GiftCertificates.Partner AS Partner,
	|	GiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.PartialPayment AS PartialPayment,
	|	CASE
	|		WHEN GiftCertificates.GiftCardAccounting25
	|			THEN UNDEFINED
	|		ELSE GiftCertificates.StatusFromHistoryOfGiftCertificates
	|	END AS StatusFromHistoryOfGiftCertificates,
	|	GiftCertificates.ActivationStatus AS ActivationStatus,
	|
	|	GiftCertificates.ValidityStartDate AS ValidityStartDate,
	|	GiftCertificates.ValidityEndDate AS ValidityEndDate,
	|	ISNULL(GiftCertificatesBalance.SumBalance, 0)
	|	* GiftCertificates.ConversionRate_1 AS Balance
	|
	|FROM TableGiftCertificates AS GiftCertificates
	|	LEFT JOIN GiftCertificatesBalance AS GiftCertificatesBalance
	|	ON GiftCertificatesBalance.GiftCertificate = GiftCertificates.GiftCertificate
	|	
	|");
	
	Query.SetParameter("Ref", GiftCertificate);
	CurrentSessionDate = CurrentDate;
	If UseCurDateOfSession Then
		CurrentSessionDate = CurrentSessionDate();
	EndIf;
	Query.SetParameter("BorderDateEndOfDay",   New Boundary(EndOfDay(CurrentSessionDate), BoundaryType.Including));
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	
	DeltaOfPaymentAmount = 0;
	FoundRows = GiftCertificates.FindRows(New Structure("GiftCertificate", GiftCertificate));	
	For Each FoundRow In FoundRows Do
		DeltaOfPaymentAmount = DeltaOfPaymentAmount + FoundRow.Sum;
		FoundRow.Sum = 0;
	EndDo;
	
	PayAmount = PayAmount - DeltaOfPaymentAmount;
	
	If OpeningModeSurcharge Then
		ItRemainsToPayExtra = ItRemainsToPayExtra + DeltaOfPaymentAmount;
	EndIf;
	
	If Selection.Next() Then
		
		If RowID = Undefined Then
			If FoundRows.Count() = 0 Then
				FoundRow = GiftCertificates.Add();
			Else
				FoundRow = FoundRows[0];
			EndIf;
		Else
			FoundRow = GiftCertificates.FindByID(RowID);
		EndIf;
		
		FoundRow.GiftCertificate  = GiftCertificate;
		FoundRow.Balance               = Selection.Balance;
		
		FoundRow.ARAPObject 		  = Selection.ARAPObject;
		FoundRow.Partner 		  	  = Selection.Partner;
		
		FoundRow.GiftCardAccounting25 = Selection.GiftCardAccounting25;
		
		FoundRow.Sum = Selection.Balance;
		If PayInAddition <> 0 Or ItRemainsToPayExtra > 0 Then
			FoundRow.Sum             = Min(ItRemainsToPayExtra, Selection.Balance);
		EndIf;
		
		FoundRow.ActivationStatus       = Selection.ActivationStatus;
		FoundRow.ValidityStartDate    = Selection.ValidityStartDate;
		FoundRow.ValidityEndDate = Selection.ValidityEndDate;
		FoundRow.PartialPayment       = Selection.PartialPayment;
		
		PayAmount = PayAmount + FoundRow.Sum;
		
		If OpeningModeSurcharge And (PayInAddition <> 0 Or ItRemainsToPayExtra > 0) Then
			ItRemainsToPayExtra = ItRemainsToPayExtra - FoundRow.Sum;
		EndIf;
	EndIf;
	
	Items.GiftCertificatesConsiderAGiftCertificate.Enabled = (Not OpeningModeSurcharge Or ItRemainsToPayExtra > 0);
	
EndProcedure

&AtServer
Procedure CheckDuplicatesOfRowsInTablePart(Cancel)
	
	Query = New Query(
	"SELECT 
	|CheckTable.LineNumber, 
	|CheckTable.GiftCertificate
	|	INTO CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CheckTable.LineNumber) AS LineNumber,
	|	SUM(1) AS DuplicateCount,
	|	CheckTable.GiftCertificate
	|INTO DuplicateLines
	|FROM
	|	CheckTable AS CheckTable
	|
	|GROUP BY 
	|	CheckTable.GiftCertificate
	|
	|HAVING
	|	SUM(1) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckTable.LineNumber,
	|	DuplicateLines.LineNumber AS FirstRow
	|FROM
	|	CheckTable AS CheckTable
	|		INNER JOIN DuplicateLines AS DuplicateLines
	|		ON CheckTable.LineNumber <> DuplicateLines.LineNumber 
	|	AND CheckTable.GiftCertificate = DuplicateLines.GiftCertificate");
	
	Table = GiftCertificates.Unload(,"GiftCertificate");
	TMCommonUse.NumberValueTable(Table, "LineNumber");
	
	Query.SetParameter("CheckTable", Table);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Dữ liệu tại dòng %LineNumber% của dnah sách ""Phiếu quà tặng"" trùng với dữ liệu tại dòng %FirstRow% theo giá trị trường ""Phiếu quà tặng"".';
							|ru = 'Данные в строке %LineNumber% списка ""Подарочные сертификаты"" совпадают с данными в строке %FirstRow% по значению поля ""Подарочный сертификат"".';
							|en = 'Data in line %LineNumber% of list ""Gift cards"" matches the data in line %FirstRow% by value of field ""Gift card"".'; fa = 'Data in line %LineNumber% of list ""Gift cards"" matches the data in line %FirstRow% by value of field ""Gift card"".';
							|it = 'I dati nella riga %LineNumber% dell''elenco ""Buoni regalo"" corrispondono con i dati nella riga %FirstRow% per il valore nel campo ""Buono regalo"".';
							|pl = 'Dane w wierszu %LineNumber% listy ""Certyfikaty podarunkowe"" sa zgodeb z danymi w wierszu %FirstRow% wg wartosci pola ""Certyfikat podarunkowy"".';
							|tr = '""Hediye kartları"" listesinin %LineNumber% satırındaki veriler, ""Hediye kartı"" alanının değeri için %FirstRow% satırdaki verilerle eşleşir.'");
		MessageText =  StrReplace(MessageText, "%LineNumber%", Selection.LineNumber + 1);
		MessageText =  StrReplace(MessageText, "%FirstRow%", Selection.FirstRow + 1);
		
		Common.MessageToUser(
			MessageText,
			Undefined,
			"GiftCertificates["+Selection.LineNumber+"].GiftCertificate",
			,
			Cancel);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckPaymentBySegment(Cancel)
	
	If Not ValueIsFilled(AddressInStorageGoods) Then
		Return
	EndIf;
	
	Query = New Query(
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Sum AS Sum
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableGiftCertificates.LineNumber AS LineNumber,
	|	TableGiftCertificates.GiftCertificate AS GiftCertificate,
	|	TableGiftCertificates.Sum AS Sum,
	|	TableGiftCertificates.Balance AS Balance
	|INTO TableGiftCertificates
	|FROM
	|	&TableGiftCertificates AS TableGiftCertificates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Segment AS Segment,
	|	SUM(Goods.Sum) AS Sum
	|INTO AmountsBySegment
	|FROM
	|	(SELECT
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Sum AS Sum,
	|		SegmentProducts.Segment AS Segment
	|	FROM
	|		GoodsTable AS GoodsTable
	|			INNER JOIN InformationRegister.SegmentProducts AS SegmentProducts
	|			ON GoodsTable.Products = SegmentProducts.Products
	|				AND GoodsTable.Characteristic = SegmentProducts.Characteristic
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Sum,
	|		VALUE(Catalog.ProductSegments.EmptyRef)
	|	FROM
	|		GoodsTable AS GoodsTable
	|			LEFT JOIN InformationRegister.SegmentProducts AS SegmentProducts
	|			ON GoodsTable.Products = SegmentProducts.Products
	|				AND GoodsTable.Characteristic = SegmentProducts.Characteristic) AS Goods
	|
	|GROUP BY
	|	Goods.Segment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Segment AS Segment,
	|	SUM(Table.PayAmount) AS PayAmount,
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.Balance) AS Balance
	|FROM
	|	(SELECT
	|		TableGiftCertificates.GiftCertificate.Owner.ProductSegment AS Segment,
	|		0 AS Sum,
	|		SUM(TableGiftCertificates.Sum) AS PayAmount,
	|		SUM(TableGiftCertificates.Balance) AS Balance
	|	FROM
	|		TableGiftCertificates AS TableGiftCertificates
	|	
	|	GROUP BY
	|		TableGiftCertificates.GiftCertificate.Owner.ProductSegment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AmountsBySegment.Segment,
	|		AmountsBySegment.Sum,
	|		0,
	|		0
	|	FROM
	|		AmountsBySegment AS AmountsBySegment) AS Table
	|
	|GROUP BY
	|	Table.Segment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableGiftCertificates.LineNumber AS TableRowNumber,
	|	TableGiftCertificates.GiftCertificate AS GiftCertificate,
	|	TableGiftCertificates.GiftCertificate.Owner AS GiftCertificateKind,
	|	TableGiftCertificates.GiftCertificate.Owner.ProductSegment AS Segment
	|FROM
	|	TableGiftCertificates AS TableGiftCertificates");
	
	TableGiftCertificates = GiftCertificates.Unload(,"GiftCertificate,Sum,Balance");
	TMCommonUse.NumberValueTable(TableGiftCertificates, "LineNumber");
	
	Query.SetParameter("TableGiftCertificates", TableGiftCertificates);
	Query.SetParameter("GoodsTable", GetFromTempStorage(AddressInStorageGoods));
	
	QueriesResults = Query.ExecuteBatch();
	
	Selection = QueriesResults[3].Select();
	TableCertificatesAndTypes = QueriesResults[4].Unload();
	
	While Selection.Next() Do
		
		LinesOfTextTemplate = New Array;
		If ValueIsFilled(Selection.Segment) Then
			LinesOfTextTemplate.Add(NStr("vi = 'Các phiếu quà tặng dạng %GiftCertificateKind% chỉ được dùng
										|để thanh toán các mặt hàng trong phân khúc ""%Segment%"".';
										|ru = 'Сертификаты вида %GiftCertificateKind% предназначены
										|только для оплаты номенклатурных позиций из сегмента ""%Segment%"".';
										|en = 'You can use gift cards of the %GiftCertificateKind% kind
										|only to pay for product items from the %Segment% segment.'; fa = 'You can use gift cards of the %GiftCertificateKind% kind
										|only to pay for product items from the %Segment% segment.';
										|it = 'I buoni di tipo %GiftCertificateKind% sono utilizzati 
										|solo per il pagamento di posizioni di nomenclatura dal segmento ""%Segment%"".';
										|pl = 'Certyfikaty z rodzajem %GiftCertificateKind% są przeznaczone
										|tylko do opłaty pozycji produktowych z segmentu""%Segment%"".';
										|tr = '%GiftCertificateKind% tipi sertifikalar 
										|yalnızca %Segment% segmentindeki öğe kalemleri için ödeme yapılmasına yöneliktir.'"));
		Else
			LinesOfTextTemplate.Add(NStr("vi = 'Các phiếu quà tặng dạng %GiftCertificateKind% chỉ được dùng
										|để thanh toán các mặt hàng.';
										|ru = 'Сертификаты вида %GiftCertificateKind% предназначены
										|только для оплаты номенклатурных позиций.';
										|en = 'You can use gift cards of the %GiftCertificateKind% kind
										|only to pay for product items.'; fa = 'You can use gift cards of the %GiftCertificateKind% kind
										|only to pay for product items.';
										|it = 'I buoni di tipo %GiftCertificateKind% sono utilizzati 
										|solo per il pagamento di posizioni di nomenclatura.';
										|pl = 'Certyfikaty z rodzajem %GiftCertificateKind% są przeznaczone
										|tylko do zapłaty pozycji produktowych.';
										|tr = '%GiftCertificateKind% tipi sertifikalar,
										| yalnızca öğe kalemleri için ödeme yapılmasına yöneliktir.'"));
		EndIf;

		If Selection.PayAmount > 0 And Selection.Sum = 0 Then
			
			GiftCertificateStrings = TableCertificatesAndTypes.FindRows(New Structure("Segment",Selection.Segment));
			
			For Each TSRow In GiftCertificateStrings Do
		
				LinesOfText = New Array;
				CommonClientServer.SupplementArray(LinesOfText, LinesOfTextTemplate);
				LinesOfText.Add(NStr("vi = 'Không thể thanh toán phiếu này bằng phiếu quà tặng.';
									|ru = 'Оплата данного чека такими сертификатами невозможна.';
									|en = 'You cannot pay this receipt with these gift cards.'; fa = 'You cannot pay this receipt with these gift cards.';
									|it = 'Questo scontrino non può essere pagato con questi buoni regalo.';
									|pl = 'Opłata tego paragonu za pomocą takich certyfikatów jest niemożliwa.';
									|tr = 'Bu makbuzun bu kuponlarla ödenmesi mümkün değildir.'"));
				
				MessageText = StrConcat(LinesOfText, " ");
				MessageText = StrReplace(MessageText, "%GiftCertificateKind%", TableCertificatesAndTypes.Find(Selection.Segment, "Segment").GiftCertificateKind);
				MessageText = StrReplace(MessageText, "%Segment%", Selection.Segment);
				
				Common.MessageToUser(
					MessageText,
					Undefined,
					"GiftCertificates["+TSRow.TableRowNumber+"].GiftCertificate",
					,
					Cancel);
				
			EndDo;
			
		EndIf;
		
		If Selection.PayAmount > 0 And Selection.Sum > 0 And Selection.Sum < Selection.PayAmount Then
			
			GiftCertificateKinds = New Array;
			For Each TSRow In TableCertificatesAndTypes.FindRows(New Structure("Segment",Selection.Segment)) Do
				KindPresentaion = """" + TSRow.GiftCertificateKind + """";
				If GiftCertificateKinds.Find(KindPresentaion) = Undefined Then
					GiftCertificateKinds.Add(KindPresentaion);
				EndIf;
			EndDo;
			
			GiftCertificateStrings = TableCertificatesAndTypes.FindRows(New Structure("Segment",Selection.Segment));
			For Each TSRow In GiftCertificateStrings Do
				
				LinesOfText = New Array;
				CommonClientServer.SupplementArray(LinesOfText, LinesOfTextTemplate);
				LinesOfText.Add(NStr("vi = 'Không thể thanh toán bằng phiếu quà tặng quá %Sum%%Currency%.';
									|ru = 'Данными сертификатами можно оплатить не более %Sum% %Currency%.';
									|en = 'With these gift cards, you can pay no more than %Sum% %Currency%.'; fa = 'With these gift cards, you can pay no more than %Sum% %Currency%.';
									|it = 'Con questi buoni è possibile pagare fino a %Sum% %Currency%.';
									|pl = 'Za pomocą tych certyfikatów można zapłacić nie więcej niż %Sum% %Currency%.';
									|tr = 'Bu sertifikalar en fazla %Sum% %Currency% kadar ödeme yapmak için kullanılabilir.'"));

				MessageText = StrConcat(LinesOfText, " ");
				MessageText =  StrReplace(MessageText, "%GiftCertificateKind%", StrConcat(GiftCertificateKinds, ","));
				MessageText =  StrReplace(MessageText, "%Segment%", Selection.Segment);
				MessageText =  StrReplace(MessageText, "%Sum%", Selection.Sum);
				MessageText =  StrReplace(MessageText, "%Currency%", Currency);
				
				Common.MessageToUser(
					MessageText,
					Undefined,
					"GiftCertificates["+TSRow.TableRowNumber+"].GiftCertificate",
					,
					Cancel);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
