
#Region Public

#Region PaymentScheduleSteps

//Performs the re-completion of the stages of the payment schedule, updates the hyperlink of the payment schedule.
//Called from the method before writing the form.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 
Procedure FormBeforeRecordingOnClientServer(Form) Export
	AdvancedParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	
	For Each ParametersStructure In AdvancedParameters.ParametersArray Do
		
		If ParametersStructure.Property("SourceOfAmountsTabularPart") And ParametersStructure.SourceOfAmountsTabularPart Then
			ParametersStructure.Delete("DocumentAmounts");
			ParametersStructure.Insert("DocumentAmounts", ARAPAccountingInternal.DocumentAmounts(Form.Object,ParametersStructure));
		EndIf;
		
		ARAPAccountingServer.CheckAndFillInAmountOfSettlements(Form, ParametersStructure, AdvancedParameters.SystemSettings_);
		ARAPAccountingServer.CheckAndFillInAmountsOfSettlementsInTablePart(Form, ParametersStructure);
		
	EndDo;
	
	PaymentStepsServer.CheckAndFillInPaymentScheduleStages(Form, AdvancedParameters);
	ARAPAccountingFormWork.UpdateHyperlinkTextPaymentSteps(Form);
EndProcedure

#EndRegion

#Region DebtLimits

// Controls the display of the debt limit in the document form
//
// Parameters:
//	Form - ClientApplicationForm - The Form where you want to update the hyperlink:
//	 * Items - FormItems - elements of the calling form
//
Procedure UpdateHyperlinkTextDebtLimit(Form) Export
	
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	SystemSettings_ = AugmentedMechanismParameters.SystemSettings_;
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.FormItems.DebtLimitationText)
			Or Not ValueIsFilled(ParametersStructure.FormItems.DebtLimitation) Then
				Return;
		EndIf;
		
		ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure, "Contract,Date");
		
		Contract                = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract);
		Date                   = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date);
		Item_Text           = Form.Items[ParametersStructure.FormItems.DebtLimitationText];
		ItemPicture1        = Form.Items[ParametersStructure.FormItems.DebtLimitation];
		ThereAreSettlementsUnderContracts = ParametersStructure.CustomerSettlementDocument And SystemSettings_.UseCustomerContracts
										Or ParametersStructure.DocumentOfSettlementsWithSuppliers And SystemSettings_.UseContractsWithVendors;
		
		If AccessRight("Read", Metadata.Catalogs.CounterpartyContracts)
			And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting)
			And ThereAreSettlementsUnderContracts Then
			
			ContractData = New Structure; 
			ContractData.Insert("LimitDebtAmount", False); 
			ContractData.Insert("AllowableAmountPayable",         0); 
			ContractData.Insert("ARAPCurrency",                 Undefined); 
			ContractData.Insert("ShipmentIsProhibitedInCaseOfARAPOverdue", False); 
			
			If ValueIsFilled(Contract) Then
				
				Query = New Query("SELECT ALLOWED
				|	CounterpartyContracts.LimitDebtAmount AS LimitDebtAmount,
				|	CounterpartyContracts.AllowableAmountPayable AS AllowableAmountPayable,
				|	CounterpartyContracts.ARAPCurrency AS ARAPCurrency,
				|	CounterpartyContracts.ShipmentIsProhibitedInCaseOfARAPOverdue AS ShipmentIsProhibitedInCaseOfARAPOverdue
				|FROM
				|	Catalog.CounterpartyContracts AS CounterpartyContracts
				|WHERE
				|	CounterpartyContracts.Ref = &Contract");
				
				Query.SetParameter("Contract", Contract);
				
				Selection = Query.Execute().Select();
				If Selection.Next() Then
					ContractData = Selection;
				EndIf;
				
			EndIf;
			
			AmountExceeded = False;
			If ContractData.LimitDebtAmount Then
				RemainingAllowedCredit = RemainingAllowedCredit(Contract, ContractData.AllowableAmountPayable);
				AmountExceeded = RemainingAllowedCredit < 0;
			EndIf;
			
			DeadlineExceeded = False;
			If ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue Then
				AmountOfOverdueDebt = AmountOfOverdueDebt(Contract, Date);
				DeadlineExceeded = AmountOfOverdueDebt > 0;
			EndIf;
			
			If AmountExceeded Or DeadlineExceeded Then
				Item_Text.Title = NStr("vi = 'Xuất kho bị cấm';
										|ru = 'Отгрузка запрещена';
										|en = 'Shipment is prohibited'; fa = 'ارسال ممنوع است';
										|it = 'Spedizione vietata';
										|pl = 'Wysyłka zabroniona';
										|tr = 'Sevkiyat yasaklandı'");
				Item_Text.TextColor = WebColors.FireBrick;
				Item_Text.Visible = True;
				ItemPicture1.Visible = True;
			ElsIf ContractData.LimitDebtAmount Then
				Item_Text.Title = NStr("vi = 'Số dư trả sau được phép:';
										|ru = 'Остаток допустимого кредита:';
										|en = 'Allowed credit balance:'; fa = 'Allowed credit balance:';
										|it = 'Saldo del credito disponibile:';
										|pl = 'Reszta dopuszczalnego kredytu:';
										|tr = 'Mevcut kredi bakiyesi:'") + " " + Format(RemainingAllowedCredit, "NFD=2; NZ=0,00") + " " + String(ContractData.ARAPCurrency);
				Item_Text.TextColor = StyleColors.HyperlinkColor;
				Item_Text.Visible = True;
				ItemPicture1.Visible = False;
			Else
				Item_Text.Visible = False;
				ItemPicture1.Visible = False;
			EndIf;
			
		Else
			
			Item_Text.Visible = False;
			ItemPicture1.Visible = False;
			
		EndIf;
	EndDo;
	
EndProcedure

// Returns the amount of overdue debt according to the data of settlements with the client
//
// Parameters:
//	Contract       - CatalogRef.CounterpartyContracts - Agreement that determines the client's debt
//	DocumentDate - Date - Date of the document that is being monitored for the amount of overdue debt.
//
// Returns:
//	Number
//
Function AmountOfOverdueDebt(Contract, DocumentDate) Export
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		Query = New Query("
		|SELECT
		|	CustomersARAPAccountingBalance.DebtBalance AS ARAPOverdue
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
		|		,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				DimensionByPartners.DimensionKey AS DimensionKey
		|			FROM
		|				InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
		|			WHERE
		|				DimensionByPartners.Contract = &Contract
		|			) AND PlannedRepaymentDate < &DebtTermControlPeriod
		|	) AS CustomersARAPAccountingBalance
		|
		|WHERE
		|	CustomersARAPAccountingBalance.DebtBalance > 0
		|");
		Query.SetParameter("DebtTermControlPeriod", BegOfDay(Max(CurrentSessionDate(), DocumentDate)));
	Else
		Query = New Query("
		|SELECT
		|	ISNULL(SUM(CASE WHEN CustomersARAPAccountingBalance.SumBalance >
		|			CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance THEN
		|		CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance
		|	ELSE
		|		CustomersARAPAccountingBalance.SumBalance
		|	END), 0) AS ARAPOverdue
		|
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(
		|		&DebtTermControlPeriod,
		|		AccountingDimensionByPartners IN (
		|			SELECT
		|				DimensionByPartners.DimensionKey AS DimensionKey
		|			FROM
		|				InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
		|			WHERE
		|				DimensionByPartners.Contract = &Contract
		|			)
		|	) AS CustomersARAPAccountingBalance
		|
		|WHERE
		|	CustomersARAPAccountingBalance.SumBalance > 0
		|	AND (CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance) > 0
		|");
		Query.SetParameter("DebtTermControlPeriod", Max(EndOfDay(CurrentSessionDate()), EndOfDay(DocumentDate)));
	EndIf;
	
	Query.SetParameter("Contract", Contract);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		AmountOfOverdueDebt = Selection.ARAPOverdue;
	Else
		AmountOfOverdueDebt = 0;
	EndIf;
	
	Return AmountOfOverdueDebt;
	
EndFunction

// Returns the balance of the allowed loan based on the data of settlements with the client and the allowed amount of debt.
//
// Parameters:
//	Contract          - CatalogRef.CounterpartyContracts - Agreement that determines the client's debt
//	AllowableCredit - Number - The value of the allowed amount of debt.
//
// Returns:
//	Number
//
Function RemainingAllowedCredit(Contract, AllowableCredit) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	CustomersARAPAccountingBalance.SumBalance + CustomersARAPAccountingBalance.BeingShippedBalance AS OutstandingDebt
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|		,
	|		AccountingDimensionByPartners IN (
	|			SELECT
	|				DimensionByPartners.DimensionKey AS DimensionKey
	|			FROM
	|				InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|			WHERE
	|				DimensionByPartners.Contract = &Contract
	|			)
	|	) AS CustomersARAPAccountingBalance
	|");
	Query.SetParameter("Contract", Contract);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		RemainingAllowedCredit = AllowableCredit - Selection.OutstandingDebt;
	Else
		RemainingAllowedCredit = AllowableCredit;
	EndIf;
	
	Return RemainingAllowedCredit;
	
EndFunction

#EndRegion

#Region ARAPObjects

// The function returns the name of the form to open.
//
// Parameters:
//	Var_Key - CatalogRef.ARAPObjects - Link to the calculation Objects reference list item.
//
// Returns:
//	Structure:
//	 * Form - String - full name of the form.
//	 * Key - DefinedType.ARAPObject - A link to the calculation object being opened.
//
Function FormOfCalculationObject(Var_Key) Export
	
	ObjectReference = Common.ObjectAttributeValue(Var_Key, "Object");
	If ValueIsFilled(ObjectReference) Then
		ObjectMetadata = ObjectReference.Metadata();
		
		Result = New Structure();
		Result.Insert("Form",Common.TableNameByRef(ObjectReference) + ".Form." + ObjectMetadata.DefaultObjectForm.Name);
		Result.Insert("Key",Common.ObjectAttributeValue(Var_Key, "Object"));
	Else
		Result = New Structure();
		Result.Insert("Form","");
		Result.Insert("Key",Undefined);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ObjectOfCalculationsBasisOfPaymentProcessingOfReceiptOfSelectionData(ChoiceData, SelectionSettings, ThisIsWhip, ThisIsASettlementObject) Export
	
	ChoiceData = New ValueList;
	
	If Not ThisIsASettlementObject Then
		TypesOfBases_ = New Array;
		MetadataOfDocument = SelectionSettings.EditableDocument.Metadata();
		If MetadataOfDocument <> Undefined Then
			If MetadataOfDocument.TabularSections.Find("ARAPDetails") = Undefined Then
				TypeDescription = MetadataOfDocument.Attributes.PaymentPurpose.Type;
			Else
				TypeDescription = MetadataOfDocument.TabularSections.ARAPDetails.Attributes.PaymentPurpose.Type;
			EndIf;
			TypesOfBases_ = TypeDescription.Types();
		EndIf;
		SelectionSettings.Insert("TypesOfBases_", TypesOfBases_);
	EndIf;
	
	If ThisIsASettlementObject Then
		ARAPAccountingServer.FillInDataOfCalculationObjectSelection(
			ChoiceData,
			SelectionSettings);
	ElsIf ThisIsWhip Then
		ARAPAccountingServer.FillInUIPSelectionData(
			ChoiceData,
			SelectionSettings);
	Else
		ARAPAccountingServer.FillInDataForSelectingPaymentBasis(
			ChoiceData,
			SelectionSettings);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Disables the issue of switching to a new settlement architecture
//
Procedure DisableIssueOfSwitchingToOnlineSettlements() Export
	
	Constants.DoNotAskAboutSwitchingToOnlineARAPAccounting.Set(True);
	
EndProcedure

// Place the order amounts in temporary storage.
// 
// Parameters:
//  FormDataStructure - FormDataStructure - Data of the Form to return the VT address to.
// 
// Returns:
//  String - the address in the temporary storage.
Function PlaceOrderAmountsInTemporaryStorage(Val FormDataStructure, Val ParametersStructure) Export
	If ParametersStructure.SourceOfAmountsTabularPart Then
		Return PutToTempStorage(ARAPAccountingServer.TableOfOrderAmounts(FormDataStructure, ParametersStructure), New UUID());
	Else
		Return "";
	EndIf;
EndFunction

#EndRegion

#EndRegion
