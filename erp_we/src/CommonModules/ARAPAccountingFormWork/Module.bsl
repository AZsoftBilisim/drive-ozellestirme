#Region Public

//Adds and caches the mechanism parameters to the form details, updates the hyperlink texts
//, and sets the visibility of the "payment Offset" command for new documents.
//
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForDocuments, CatalogItemFormExtension - The form of the document/directory.
// 
Procedure FormWhenCreatedOnServer(Form) Export
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form,"MechanismDataCache")
		And Form.MechanismDataCache.Property("ARAPAccounting") Then
		MechanismParameters = Form.MechanismDataCache.ARAPAccounting.ParametersArray;
	Else
		ObjectManager = Common.ObjectManagerByFullName(Form.FormName);
		MechanismParameters = ObjectManager.SettlementParameters_(Form.Object);
	
		AddAndCacheParameters(Form, MechanismParameters);
	EndIf;
	
	SetConditionalAppearance(Form);
	
	Object = Form.Object; //FormDataStructure
	
	If ValueIsFilled(Object.Ref) Then
		If Form.ReadOnly Then
			Return;
		EndIf;
		If TypeOf(MechanismParameters) = Type("Array") Then
			ParametersArray = MechanismParameters;
		Else
			ParametersArray = CommonClientServer.ValueInArray(MechanismParameters);
		EndIf;
		For Each ParametersStructure In ParametersArray Do
			If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps)
				And ParametersStructure.ThisIsOrder
				And Not TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ShipInOneDay) Then
				TabularSection = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps);
				TableOfPaymentStages = TabularSection.Unload();
				TableOfPaymentStages.Clear();
				PaymentStepsServer.CheckAndFillInPaymentScheduleStages(Form, ParametersStructure, TableOfPaymentStages);
				ParametersStructure.ThereAreManualChangesToPaymentSchedule = Not ARAPAccountingInternal.TablesAreEqual(TableOfPaymentStages, TabularSection.Unload());
			EndIf;
		EndDo;
		Return;
	Else
		FormWhenReadingCreatingOnServer(Form, MechanismParameters)
	EndIf;
	
	BlockSettlementObjects(Form);
	
EndProcedure

//Caches the mechanism parameters in the form details, updates the hyperlink texts
//, and sets the visibility of the "payment Offset" command for existing documents.
//
// Parameters:
// 	Form - ClientApplicationForm, ManagedFormExtensionForDocuments, CatalogItemFormExtension - The form of the document/directory.
// 
Procedure FormWhenReadingOnServer(Form) Export
	
	ObjectManager = Common.ObjectManagerByFullName(Form.FormName);
	MechanismParameters = ObjectManager.SettlementParameters_(Form.Object);
	
	AddAndCacheParameters(Form, MechanismParameters);
	
	FormWhenReadingCreatingOnServer(Form, MechanismParameters)
	
EndProcedure

//Updates the hyperlink texts after recording and sets the values of the parameters of the mechanism of Mutual settlements on notification
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	AdditionalProperties - Structure - Additional properties of the recorded object
// 
Procedure FormAfterRecordingOnServer(Form, AdditionalProperties = Undefined) Export
	
	ARAPAccountingServerCall.UpdateHyperlinkTextDebtLimit(Form);
	UpdateHyperlinkTextStateOfCalculations(Form);
	ARAPAccountingClientServer.UpdateHyperlinkText(Form);
	UpdateHyperlinkTextPaymentSteps(Form);
	UpdateDistributedDecryptionAmount(Form);
	If AdditionalProperties <> Undefined Then
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		If AdditionalProperties.Property("NotifyAboutCompletionOfStages") Then
			AugmentedMechanismParameters.NotifyAboutCompletionOfStages = AdditionalProperties.NotifyAboutCompletionOfStages;
		EndIf;
		If AdditionalProperties.Property("NotifyAboutChangesToPaymentObject") Then 
			AugmentedMechanismParameters.NotifyAboutChangesToPaymentObject = AdditionalProperties.NotifyAboutChangesToPaymentObject;
			AugmentedMechanismParameters.ModifiedCalculationObject = AdditionalProperties.ModifiedCalculationObject;
		EndIf;
	EndIf;
	
EndProcedure

//Performs the necessary actions when changing the key details of the document / directory.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
//	ChangedBankingDetails - Array of String - The list of names of the changed details in terms of the document.
//						- Structure - The list of names of the changed details in terms of the document, only the keys (names of the details) of the structure are analyzed.
//						- String - The name of the changed props.
// 	TheseAreMechanismChanges - Boolean - Flag that the call is made by the mechanism itself.
// 
// Returns:
// 	Structure - The structure of the changed document details after processing, where the Key is the Name of the detail, the value is the value of the detail before the change.
//
Function FormWhenChangingBankingDetails(Form, ChangedBankingDetails, TheseAreMechanismChanges = False) Export
	
	If TypeOf(ChangedBankingDetails) = Type("Array") Then
		AttributesArray = ChangedBankingDetails;
	ElsIf TypeOf(ChangedBankingDetails) = Type("Structure") Then
		AttributesArray = New Array;
		For Each Item In ChangedBankingDetails Do
			AttributesArray.Add(Item.Key);
		EndDo;
	Else //String
		AttributesArray = New Array;
		Attributes = StrSplit(ChangedBankingDetails, ",");
		For Each Attribute In Attributes Do
			AttributesArray.Add(TrimAll(Attribute));
		EndDo;
	EndIf;
	
	OldValuesOfChangedProps = New Structure;
	ThereAreCurrencyChanges = False;
	CurrencyExchangeRateHasBeenChanged = False;
	
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	
	//If the parameter that affects the parameters of the mechanism of a particular object has changed, then they need to be recached.
	YouNeedToRecashParameters = False;
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		ArrayOfInfluencingProps = StrSplit(ParametersStructure.InfluencingAttributes,",");
		For Each InfluencingAttribute In ArrayOfInfluencingProps Do
			If AttributesArray.Find(TrimAll(InfluencingAttribute)) <> Undefined Then
				YouNeedToRecashParameters = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If YouNeedToRecashParameters Then
		WhenChangingParametersOfMechanism(Form);
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	EndIf;
	
	SystemSettings_ = AugmentedMechanismParameters.SystemSettings_;
	
	//Returns which of the changed details are used in parameter structures.
	Results = ArrayOfParameterStructuresByBankingDetails(AugmentedMechanismParameters.ParametersArray, AttributesArray);
	
	For Each Result In Results Do
		
		ParametersStructure = Result.ParametersStructure;
		ArrayOfBankingDetailsUsed = Result.DetailsUsed;
		
		UpdateHyperlinkTextDebtLimit = False;
		UpdateHyperlinkTextStateOfCalculations = False;
		UpdateHyperlinkTextPaymentSteps = False;
		SetVisibilityOffsetPayment = False;
		SetVisibilityOfFAG = False;
		ExecutionScheduleChanged = False;
		
		//Schedule the execution of the contract
		If ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined Then
			
			UpdateHyperlinkTextDebtLimit = True;
			
			Contract = TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.Contract);
			If ValueIsFilled(Contract) Then
				If TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
					SetPrivilegedMode(True);
					ContractDetails_ = Common.ObjectAttributesValues(Contract, "ExecutionScheduleIsSpecified, ContractSchedule, ContractRateOption, Organization, Counterparty");
					SetPrivilegedMode(False);
					ExecutionScheduleIsSpecified = ContractDetails_.ExecutionScheduleIsSpecified;
					ParametersStructure.ContractSchedule = ContractDetails_.ContractSchedule;
					ParametersStructure.OrganizationOfContract      = ContractDetails_.Organization;
					ParametersStructure.CounterpartyOfContract       = ContractDetails_.Counterparty;
					ParametersStructure.ContractRateOption     = ContractDetails_.ContractRateOption;
				Else
					ExecutionScheduleIsSpecified = False;
					ParametersStructure.ContractSchedule = Undefined;
					SetPrivilegedMode(True);
					ParametersStructure.ContractRateOption = Common.ObjectAttributeValue(Contract, "ContractRateOption");
					SetPrivilegedMode(False);
					ParametersStructure.OrganizationOfContract  = Catalogs.Companies.EmptyRef();
					ParametersStructure.CounterpartyOfContract   = Catalogs.Counterparties.EmptyRef();
				EndIf;
			Else
				ExecutionScheduleIsSpecified = False;
				ParametersStructure.ContractSchedule = Undefined;
				ParametersStructure.ContractRateOption = Enums.ContractRateOptions.Mutable;
				ParametersStructure.OrganizationOfContract  = Catalogs.Companies.EmptyRef();
				ParametersStructure.CounterpartyOfContract   = Catalogs.Counterparties.EmptyRef();
			EndIf;
			
			If ParametersStructure.ExecutionScheduleIsSpecified <> ExecutionScheduleIsSpecified Then
				ExecutionScheduleChanged = True;
			EndIf;
			
			ParametersStructure.ExecutionScheduleIsSpecified = ExecutionScheduleIsSpecified;
			If CommonClientServer.HasAttributeOrObjectProperty(Form, "ExecutionScheduleIsSpecified") Then
				Form.ExecutionScheduleIsSpecified = ExecutionScheduleIsSpecified;
			EndIf; 
			
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("Terms") <> Undefined Then
			Terms = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Terms);
			If ValueIsFilled(Terms) Then
				DetailsOfAgreement = ARAPAccountingInternal.DetailsOfAgreement(Terms);
				ParametersStructure.Calendar                      = DetailsOfAgreement.Calendar;
				ParametersStructure.DeadlineOfTransferOfTitleToGoods = DetailsOfAgreement.DeadlineOfTransferOfTitleToGoods;
				If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					PaymentSchedule = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.PaymentSchedule);
					If PaymentSchedule <> Undefined And PaymentSchedule.Data[PaymentSchedule.Name] <> DetailsOfAgreement.PaymentSchedule Then
						OldValuesOfChangedProps.Insert(PaymentSchedule.Name, PaymentSchedule.Data[PaymentSchedule.Name]);
						PaymentSchedule.Data[PaymentSchedule.Name] = DetailsOfAgreement.PaymentSchedule;
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
		
		//Procedure of settlements
		If (ArrayOfBankingDetailsUsed.Find("Terms") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("CommissionAgentSAgreement") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("InvoiceForOrders") <> Undefined)
			And ValueIsFilled(ParametersStructure.ARAPObjectSettings)
			And TypeOf(ParametersStructure.ARAPObjectSettings) = Type("String") 
			And StrOccurrenceCount(ParametersStructure.ARAPObjectSettings, ".") = 1 Then
			
			DefaultCalculationOrder = ARAPAccountingInternal.CalculationProcedureForParameters(Form, ParametersStructure);
			ARAPObjectSettings = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.ARAPObjectSettings);
			
			If ARAPObjectSettings.Data[ARAPObjectSettings.Name]<> DefaultCalculationOrder 
				Or ExecutionScheduleChanged Then
				OldValuesOfChangedProps.Insert(ARAPObjectSettings.Name, ARAPObjectSettings.Data[ARAPObjectSettings.Name]);
				ARAPObjectSettings.Data[ARAPObjectSettings.Name] = DefaultCalculationOrder;
				
				If ArrayOfBankingDetailsUsed.Find("ARAPObjectSettings") = Undefined Then
					ArrayOfBankingDetailsUsed.Add("ARAPObjectSettings");
				EndIf;
				
				UpdateHyperlinkTextStateOfCalculations = True;
				UpdateHyperlinkTextPaymentSteps = True;
				SetVisibilityOffsetPayment = True;
			EndIf;
			
			SetVisibilityOfFAG = True;
			
		EndIf;
		
		// Currency exchange rate of the Contract and the date of the currency exchange rate of the document
		If ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined Then
			If ParametersStructure.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
				CurrencyExchangeRateHasBeenChanged = True;
			EndIf;
			If ParametersStructure.ContractRateOption <> Enums.ContractRateOptions.Mutable 
				And ValueIsFilled(ParametersStructure.DocumentExchangeRateDate) Then
				DocumentExchangeRateDate = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.DocumentExchangeRateDate);
				If ValueIsFilled(DocumentExchangeRateDate.Data[DocumentExchangeRateDate.Name]) Then
					DocumentExchangeRateDate.Data[DocumentExchangeRateDate.Name] = Date(1, 1, 1);
					CurrencyExchangeRateHasBeenChanged = True;
				EndIf;
			EndIf;
		EndIf;
		
		//FAG
		If (ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("CommissionAgentSAgreement") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("Terms") <> Undefined)
			And ValueIsFilled(ParametersStructure.FinancialAccountingGroup) Then
			
			DefaultHFCS = ARAPAccountingInternal.DefaultHFCS(Form, ParametersStructure, SystemSettings_);
			
			HFCProps = TMCommonUseClientServer.DataForAssignment(Form,ParametersStructure.FinancialAccountingGroup);
			If HFCProps <> Undefined And Not Common.IsReference(TypeOf(HFCProps.Data)) Then
				HFCProps.Data[HFCProps.Name] = DefaultHFCS;
			EndIf;
			
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("InvoiceForOrders") <> Undefined Then
			SetVisibilityOffsetPayment = True;
			SetVisibilityOfFAG = True;
			ClearPaymentDecryption(Form, ParametersStructure);
		EndIf;
		
		//Payment in foreign currency
		If ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("CommissionAgentSAgreement") <> Undefined Then
			
			PaymentInDefaultCurrency = ARAPAccountingInternal.PaymentInDefaultCurrency(Form, ParametersStructure);
			ForeignCurrencyTransaction = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.ForeignCurrencyTransaction);
			
			If ForeignCurrencyTransaction <> Undefined And ForeignCurrencyTransaction.Data[ForeignCurrencyTransaction.Name]<> PaymentInDefaultCurrency Then
				OldValuesOfChangedProps.Insert(ForeignCurrencyTransaction.Name, ForeignCurrencyTransaction.Data);
				ForeignCurrencyTransaction.Data[ForeignCurrencyTransaction.Name] = PaymentInDefaultCurrency;
			EndIf;
		EndIf;
		
		//Payment schedule
		If ArrayOfBankingDetailsUsed.Find("Terms") <> Undefined Or ExecutionScheduleChanged Then
			//Clearing the schedule of payment stages
			If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
				ARAPAccountingInternal.ClearPaymentScheduleStages(Form, ParametersStructure);
			ElsIf ValueIsFilled(ParametersStructure.PaymentDate) Then
				Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.PaymentDate);
				Attribute.Data[Attribute.Name] = Date(1,1,1);
			EndIf;
			UpdateHyperlinkTextPaymentSteps = True;
		ElsIf ArrayOfBankingDetailsUsed.Find("Date") <> Undefined 
			And ValueIsFilled(ParametersStructure.PaymentDate) 
			And ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentDate))Then
			PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
			PaymentDateCalculationParameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate");
			PaymentDateCalculationParameters.DateOfShipment   = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date);
			PaymentDateCalculationParameters.PaymentDate    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentDate);
			PaymentDateCalculationParameters.Calendar      = ParametersStructure.Calendar;
			If ValueIsFilled(ParametersStructure.Calendar) Then
				PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(PaymentDateCalculationParameters);
			Else
				PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(PaymentDateCalculationParameters);
			EndIf;
			Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.PaymentDate);
			Attribute.Data[Attribute.Name] = PaymentDate;
			UpdateHyperlinkTextPaymentSteps = True;
		ElsIf ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps)
			And (ArrayOfBankingDetailsUsed.Find("Date") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("DateOfShipment") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("DateOfReceipt") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("ApprovalDate") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("ShipInOneDay") <> Undefined) Then
				
				UpdateHyperlinkTextPaymentSteps = UpdateHyperlinkTextPaymentSteps 
					Or PaymentStepsServer.RecalculatePaymentDatesPaymentMilestones(Form, ParametersStructure, ArrayOfBankingDetailsUsed);
				
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("Organization") <> Undefined
			And ParametersStructure.IsItPaymentOrOtherDocument Then
			
			ArrayOfCalculationObjects_ = SettlementObjectsAvailableByOrganization(Form, ParametersStructure);
			ClearObjectAndAmountOfPaymentDecryption(Form, ParametersStructure, ArrayOfCalculationObjects_);
			
		ElsIf ArrayOfBankingDetailsUsed.Find("Organization") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Terms") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Partner") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Counterparty") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("LineOfBusiness") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("ARAPCurrency") <> Undefined Then
			
			ClearObjectAndAmountOfPaymentDecryption(Form, ParametersStructure);
			
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("Organization") <> Undefined Then
			
			Organization = TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.Organization);
			LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			
			If ValueIsFilled(ParametersStructure.DocumentCurrency) 
				And Not ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.DocumentCurrency)) Then
				Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.DocumentCurrency);
				Attribute.Data[Attribute.Name] = LocalAccountingCurrency;
				ThereAreCurrencyChanges = True;
			EndIf;
			
			If ValueIsFilled(ParametersStructure.ARAPCurrency)
				And Not ParametersStructure.CurrencyOfMutualSettlementsInLines
				And Not ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.ARAPCurrency)) Then
				Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.ARAPCurrency);
				Attribute.Data[Attribute.Name] = LocalAccountingCurrency;
				ThereAreCurrencyChanges = True;
			EndIf;
			
		EndIf;
		
		If (ArrayOfBankingDetailsUsed.Find("Organization") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Counterparty") <> Undefined)
			And ParametersStructure.IsItPaymentOrOtherDocument
			And ValueIsFilled(ParametersStructure.Contract) 
			And (TypeOf(TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.Contract)) <> Type("CatalogRef.CounterpartyContracts")
				Or ParametersStructure.OrganizationOfContract <> TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.Organization)
				Or ParametersStructure.CounterpartyOfContract <> TMCommonUseClientServer.DataAlongWay(Form.Object, ParametersStructure.Counterparty)) Then
			
			Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.Contract);
			Attribute.Data[Attribute.Name] = Undefined;
			
			If ArrayOfBankingDetailsUsed.Find("Contract") = Undefined Then
				ArrayOfBankingDetailsUsed.Add("Contract");
			EndIf;
			
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("DocumentCurrency") <> Undefined 
			Or ArrayOfBankingDetailsUsed.Find("ARAPCurrency") <> Undefined 
			Or ArrayOfBankingDetailsUsed.Find("DocumentAmount") <> Undefined 
			Or ArrayOfBankingDetailsUsed.Find("AmountARAP") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("DocumentExchangeRateDate") <> Undefined Then
			
			ArrayOfClearedFields = New Array;
			If ArrayOfBankingDetailsUsed.Find("DocumentCurrency") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("DocumentAmount") <> Undefined Then
				ArrayOfClearedFields.Add("PaymentAmount");
				ArrayOfClearedFields.Add("PackageDepositValue");
				ArrayOfClearedFields.Add("AmountARAP");
				ArrayOfClearedFields.Add("AmountARAPByPackage");
			ElsIf ArrayOfBankingDetailsUsed.Find("ARAPCurrency") <> Undefined 
				Or ArrayOfBankingDetailsUsed.Find("AmountARAP") <> Undefined Then
				ArrayOfClearedFields.Add("AmountARAP");
				ArrayOfClearedFields.Add("AmountARAPByPackage");
			EndIf;
			
			ClearPaymentScheduleStageFields(Form, ParametersStructure, ArrayOfClearedFields);
			ARAPAccountingInternal.ClearAmountsOfTSSettlements(Form, ParametersStructure);
			
			If Not TheseAreMechanismChanges And ValueIsFilled(ParametersStructure.AmountARAP) Then
				Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.AmountARAP);
				Attribute.Data[Attribute.Name] = 0;
			EndIf;
			
			ARAPAccountingServer.CheckAndFillInAmountsOfSettlementsInTablePart(Form, ParametersStructure);
			ARAPAccountingClientServer.UpdateHyperlinkText(Form,ParametersStructure);
			
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("PaymentDate") <> Undefined Then
			UpdateHyperlinkTextPaymentSteps = True;
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("DocumentCurrency") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("ARAPCurrency") <> Undefined Then
			ThereAreCurrencyChanges = True;
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("ARAPObjectSettings") <> Undefined Then
			// It is necessary to clear the calculation objects in order to correctly determine the State of calculations
			ARAPAccountingInternal.ClearCalculationObject(Form, ParametersStructure);
			ARAPAccountingInternal.ClearPaymentScheduleStages(Form, ParametersStructure);
			UpdateHyperlinkTextPaymentSteps = True;
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("ARAPObjectSettings") <> Undefined 
			Or ArrayOfBankingDetailsUsed.Find("ARAPCurrency") <> Undefined Then
			ClearPaymentDecryption(Form, ParametersStructure);
			SetVisibilityOffsetPayment = True;
			UpdateHyperlinkTextStateOfCalculations = True;
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("CourseNumerator") <> Undefined 
			Or ArrayOfBankingDetailsUsed.Find("CourseDenominator") <> Undefined Then
			CurrencyExchangeRateHasBeenChanged = True;
		EndIf;
		
		If UpdateHyperlinkTextDebtLimit Then
			ARAPAccountingServerCall.UpdateHyperlinkTextDebtLimit(Form);
		EndIf;
		
		If UpdateHyperlinkTextStateOfCalculations Then
			UpdateHyperlinkTextStateOfCalculations(Form);
		EndIf;
		
		If UpdateHyperlinkTextPaymentSteps Then
			UpdateHyperlinkTextPaymentSteps(Form, ParametersStructure, SystemSettings_);
		EndIf;
		
		If SetVisibilityOffsetPayment Then
			SetVisibilityOffsetPayment(Form, ParametersStructure);
		EndIf;
		
		If SetVisibilityOfFAG Then
			SetVisibilityOfFAG(Form, ParametersStructure);
		EndIf;
		
		If ArrayOfBankingDetailsUsed.Find("Organization") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("InvoiceForOrders") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Partner") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Counterparty") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Contract") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("Terms") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("CommissionAgentSAgreement") <> Undefined Then
			SetLBEditingOption(Form, ParametersStructure);
		EndIf;
		
		//When changing the order of payments, check the visibility of the set-off payment
		//When changing the amount of the document on the form, reformulate the currency label, all hyperlinks
		//When changing the date, the date of the bank, conducted by the bank, clear the amount of mutual settlements decryption
	EndDo;
	
	If Not TheseAreMechanismChanges And ThereAreCurrencyChanges And ValueIsFilled(ParametersStructure.CourseNumerator) Then
		OldValuesOfChangedProps.Insert("CourseNumerator", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CourseNumerator));
		OldValuesOfChangedProps.Insert("CourseDenominator", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CourseDenominator));
		ARAPAccountingInternal.FillCourseMultiplicityByDefault(Form, AugmentedMechanismParameters);
		ARAPAccountingClientServer.UpdateHyperlinkText(Form,ParametersStructure);
	ElsIf CurrencyExchangeRateHasBeenChanged Then
		ARAPAccountingClientServer.UpdateHyperlinkText(Form,ParametersStructure);
	EndIf;
	
	TMCommonUse.SaveEngineDataToFormCache(Form, "ARAPAccounting", AugmentedMechanismParameters);
	
	Return OldValuesOfChangedProps;
	
EndFunction

//Updates hyperlink texts and visibility of the "payment Offset" command.
//Cleans all the details of settlement, if the document does not change the mutual.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 
Procedure WhenChangingParametersOfMechanism(Form) Export
	
	ObjectManager = Common.ObjectManagerByFullName(Form.FormName);
	MechanismParametersAreNew = ObjectManager.SettlementParameters_(Form.Object);
	ConfigurationData = ARAPAccountingServer.AugmentedMechanismParameters(Form, MechanismParametersAreNew);
	
	ParametersArray = Form.MechanismDataCache["ARAPAccounting"].ParametersArray;
	For Each ParametersStructure In ParametersArray Do
		If ParametersArray.Count() <> ConfigurationData.ParametersArray.Count()
			Or ParametersStructure.PaymentType_ <> ConfigurationData.ParametersArray[ParametersArray.Find(ParametersStructure)].PaymentType_ Then
			ClearPaymentDecryption(Form, ParametersStructure);
			ARAPAccountingInternal.ClearCalculationObject(Form,ParametersStructure);
		EndIf;
	EndDo;
	
	For Each ParametersStructure In ConfigurationData.ParametersArray Do
		
		// We clear all the entities of the mechanism if there are no settlements with customers or suppliers.
		If Not ParametersStructure.ChangesCalculations Then
			
			AmountARAP = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.AmountARAP);
			If ValueIsFilled(AmountARAP) Then
				AmountARAP.Data[AmountARAP.Name] = 0;
			EndIf;
			
			AmountARAPByPackage = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.AmountARAPByPackage);
			If ValueIsFilled(AmountARAPByPackage) Then
				AmountARAPByPackage.Data[AmountARAPByPackage.Name] = 0;
			EndIf;
			
			ARAPAccountingInternal.ClearAmountsOfTSSettlements(Form, ParametersStructure);
			
		EndIf;
		
		If Not ParametersStructure.ChangesPaymentPlan
			// Returns of goods.
			Or ValueIsFilled(ParametersStructure.FormItems.HyperlinkPaymentDecryption)
			Or ParametersStructure.KeepCommissionFee Then
			If Not ParametersStructure.OrderAsAProformaInvoice
				Or ParametersStructure.KeepCommissionFee Then
				ARAPAccountingInternal.ClearPaymentScheduleStages(Form, ParametersStructure);
			EndIf;
		EndIf;
		
	EndDo;
	
	TMCommonUse.SaveEngineDataToFormCache(Form, "ARAPAccounting", ConfigurationData);
	
	SetVisibilityOffsetPayment(Form);
	SetVisibilityOfFAG(Form);
	SetLBEditingOption(Form);
	ARAPAccountingServerCall.UpdateHyperlinkTextDebtLimit(Form);
	UpdateHyperlinkTextPaymentSteps(Form);
	UpdateHyperlinkTextStateOfCalculations(Form);
	ARAPAccountingClientServer.UpdateHyperlinkText(Form);
	
EndProcedure

// Used for the processing of alerts related to the mechanism of mutual settlements.
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	 * Data Object Forms
// 	  ** Link - Document link, Reference link
// 	EventName - String - event name.
// 	Parameter - Arbitrary - event parameter.
Procedure NotificationProcessing(Form, EventName, Parameter) Export
	
	FormObject = Form.Object; //DocumentObject
	
	If (EventName = "PaymentCredited" And Parameter = FormObject.Ref) 
		Or ChangedPaymentDocumentsForCustomers(EventName)
		Or SupplierPaymentDocumentsChanged(EventName) Then
		ARAPAccountingServerCall.UpdateHyperlinkTextDebtLimit(Form);
		ARAPAccountingFormWork.UpdateHyperlinkTextStateOfCalculations(Form);
		
		Parameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		For Each Structure In Parameters.ParametersArray Do
			Structure.AddressPaymentDecryption = "";
		EndDo;
		If Not Form.Modified Then
			Form.Read();
		EndIf;
		
	EndIf;
	
	//Update the debt limit
	
EndProcedure

//Places the table part of the payment Description in temporary storage and writes a link to it in the structure of settlement parameters.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	TagName - String - Name of the element that can be used to determine which structure of settlement parameters the decryption is placed for.
//
Procedure PlacePaymentDecryptionInTemporaryStorage(Form, TagName = Undefined) Export
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	If TagName <> Undefined Then
		ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, TagName);
	Else
		ParametersStructure = MechanismParameters.ParametersArray[0];
	EndIf;
	
	ARAPDetails = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentDecryption);
	VT = ARAPDetails.Unload();
	ParametersStructure.AddressPaymentDecryption = PutToTempStorage(VT, New UUID());
	
	TMCommonUse.SaveEngineDataToFormCache(Form, "ARAPAccounting", MechanismParameters);
	
EndProcedure

Procedure DownloadPaymentTranscriptFromTemporaryStorage(Form) Export
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersArray = MechanismParameters.ParametersArray;
	For Each ParametersStructure In ParametersArray Do
		If ValueIsFilled(ParametersStructure.AddressPaymentDecryption) Then
			
			ARAPDetails = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentDecryption);
			NewPaymentDecryption = GetFromTempStorage(ParametersStructure.AddressPaymentDecryption);
			Copy = ARAPDetails.Unload();
			
			ARAPDetails.Clear();
			For Each CurRow In NewPaymentDecryption Do
				NewRow = ARAPDetails.Add();
				FillPropertyValues(NewRow, CurRow);
				If CommonClientServer.HasAttributeOrObjectProperty(NewRow, "Vendor") 
					And CommonClientServer.HasAttributeOrObjectProperty(CurRow, "Partner") Then
					NewRow.Vendor = CurRow.Partner;
				EndIf;
				If CommonClientServer.HasAttributeOrObjectProperty(NewRow, "CashFlowItem") Then
					CopyLines = Copy.FindRows(New Structure("ARAPObject", NewRow.ARAPObject));
					If CopyLines.Count()> 0 Then
						NewRow.CashFlowItem = CopyLines[0].CashFlowItem;
					EndIf;
				EndIf;
			EndDo;
			
			DeleteFromTempStorage(ParametersStructure.AddressPaymentDecryption);
			ParametersStructure.AddressPaymentDecryption = "";
			
		EndIf;
	EndDo;
	
	BlockSettlementObjects(Form);
	
EndProcedure

Procedure UpdateDistributedDecryptionAmount(Form) Export
	
	If Not CommonClientServer.HasAttributeOrObjectProperty(Form,"AllocatedAmountOfPrintName") Then
		Return;
	EndIf;
	
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersArray = AugmentedMechanismParameters.ParametersArray;
	
	For Each ParametersStructure In ParametersArray Do
		Organization            = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
		PaymentType_            = ParametersStructure.PaymentType_;
		
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
			TS = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentDecryption);
			Break;
		EndIf;
	EndDo;
	
	DistributedAmount_ = 0;
	
	If TS <> Undefined Then
		ARAPObject = New Array;
		ARAPObject.Add(ARAPObjectsServer.GetCalculationObjectFromLink(
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref), Organization, PaymentType_));
		ARAPObject.Add(ARAPObjectsServer.GetCalculationObjectFromLink(
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract), Organization, PaymentType_));
		If ValueIsFilled( ParametersStructure.OrderBase) Then
			ARAPObject.Add(ARAPObjectsServer.GetCalculationObjectFromLink(
				TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.OrderBase), Organization, PaymentType_));
		EndIf;
		
		Query = New Query("
		|SELECT
		|	Details.Sum AS Sum,
		|	Details.ARAPObject AS ARAPObject
		|INTO TTDecryption 
		|FROM &TS AS Details
		|;
		|SELECT
		|	SUM(Details.Sum) AS Sum
		|FROM
		|	TTDecryption AS Details
		|WHERE
		|	NOT Details.ARAPObject IN (&ARAPObject)
		|	AND Details.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)");
		Query.SetParameter("TS", TS.Unload());
		Query.SetParameter("ARAPObject", ARAPObject);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			DistributedAmount_ =  Selection.Sum;
		EndIf;
	EndIf;
	
	Form.AllocatedAmountOfPrintName = DistributedAmount_;
	
EndProcedure

Procedure BlockSettlementObjects(Form) Export
	
	UnlockDataForEdit(,Form.UUID);
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersArray = MechanismParameters.ParametersArray;
	For Each ParametersStructure In ParametersArray Do
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
			ARAPDetails = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentDecryption);
			For Each Page1 In ARAPDetails Do
				If ValueIsFilled(Page1.ARAPObject) Then
					//@skip-warning
					Try
						LockDataForEdit(Page1.ARAPObject,,Form.UUID);
					Except
					EndTry;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure AddAndCacheParameters(Form, FillParameters) 
	
	ConfigurationData = ARAPAccountingServer.AugmentedMechanismParameters(Form, FillParameters);
	TMCommonUse.SaveEngineDataToFormCache(Form, "ARAPAccounting", ConfigurationData);
	
EndProcedure

// Service procedure that fills in the hyperlink text of the payment rules 
// 
// Parameters:
//	Form       - ClientApplicationForm - Agreement specified in the document:
//	 * Items - FormItems - elements of the calling form
//	ParametersStructure - See ARAPAccountingServer.MechanismParameters
//	SystemSettings_  - Structure - System settings from advanced settings, if already received.
//
Procedure UpdateHyperlinkTextPaymentSteps(Form, ParametersStructure = Undefined, SystemSettings_ = Undefined) Export
	
	If ParametersStructure <> Undefined And SystemSettings_ <> Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(ParametersStructure);
	Else
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray;
		SystemSettings_ = AugmentedMechanismParameters.SystemSettings_;
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.PaymentStepsText) Then
			Continue;
		EndIf;
		
		If Not ParametersStructure.ChangesPaymentPlan And Not ParametersStructure.OrderAsAProformaInvoice Then
			Form.Items[ParametersStructure.FormItems.InscriptionStages].Visible = False;
		Else
			Form.Items[ParametersStructure.FormItems.InscriptionStages].Visible = True;
		EndIf;
		
		If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure, "PaymentDate");
		EndIf;
		
		Template = ARAPAccountingClientServer.FormattedStringOfPaymentStages(Form, ParametersStructure, SystemSettings_);
		FormattedString = StringFunctions.FormattedString(Template);
		
		Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.PaymentStepsText);
		Attribute.Data[Attribute.Name] = FormattedString;
		
		If ParametersStructure.CustomerSettlementDocument Then
			Form.Items[ParametersStructure.FormItems.InscriptionStages].Enabled = 
				AccessRight("View", Metadata.CommonForms.CustomerPaymentRules);
		Else
			Form.Items[ParametersStructure.FormItems.InscriptionStages].Enabled = 
				AccessRight("View", Metadata.CommonForms.StepsOfPaymentsToVendor);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FormWhenReadingCreatingOnServer(Form, MechanismParameters)
	
	ARAPAccountingServerCall.UpdateHyperlinkTextDebtLimit(Form);
	SetVisibilityOffsetPayment(Form);
	SetVisibilityOfFAG(Form);
	SetLBEditingOption(Form);
	UpdateHyperlinkTextPaymentSteps(Form);
	UpdateHyperlinkTextStateOfCalculations(Form);
	ARAPAccountingClientServer.UpdateHyperlinkText(Form);
	UpdateDistributedDecryptionAmount(Form);
	
EndProcedure

// Parameters:
//  Form -  ClientApplicationForm 
Procedure SetConditionalAppearance(Form)
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.FormItems.AmountOfTSSettlements) Or Not ValueIsFilled(ParametersStructure.ARAPCurrency) Then
			Continue;
		EndIf;
		
		Item = Form.ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ParametersStructure.FormItems.AmountOfTSSettlements);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ParametersStructure.DocumentCurrency);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = New DataCompositionField(ParametersStructure.ARAPCurrency);
		
		Item.Appearance.SetParameterValue("Visible", False);
		
	EndDo;
EndProcedure

Procedure SetVisibilityOffsetPayment(Form, ParametersStructure = Undefined)
	
	If ParametersStructure <> Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(ParametersStructure);
	Else
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray;
	EndIf;
	
	IsInRole = IsInRole("PaymentSettlement") Or IsInRole("FullAccess");
	
	For Each ParametersStructure In ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.FormItems.PaymentSettlement) Then
			Continue;
		EndIf;
		
		ARAPObjectSettings    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
		OrderInvoice_3  = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders, ,False);
		ThisIsOrder           = ParametersStructure.ThisIsOrder;
		IsCatalog         = ParametersStructure.IsCatalog;
		TagName        = ParametersStructure.FormItems.PaymentSettlement;
		ChangesPaymentPlan = ParametersStructure.ChangesPaymentPlan;
		KeepCommissionFee = ParametersStructure.KeepCommissionFee;
		
		If ThisIsOrder Then
			ItemVisibility = ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
								And IsInRole
								And (ChangesPaymentPlan Or ARAPObjectsServer.ReferenceIsObjectOfCalculations(Form,ParametersStructure));
		ElsIf OrderInvoice_3 Then
			ItemVisibility = ARAPObjectSettings <> Enums.ARAPObjectSettings.ByOrders
								And Not ParametersStructure.OrderAsAProformaInvoice And IsInRole And ChangesPaymentPlan;
		ElsIf IsCatalog Then
			ItemVisibility = (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
									Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) And IsInRole;
		ElsIf KeepCommissionFee Then
			ItemVisibility = False;
		Else
			ItemVisibility = IsInRole And ChangesPaymentPlan;
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, TagName, "Visible", ItemVisibility);
		
	EndDo;
	
EndProcedure

Procedure SetVisibilityOfFAG(Form, ParametersStructure = Undefined)
	
	If ParametersStructure <> Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(ParametersStructure);
	Else
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray;
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.FormItems.FinancialAccountingGroup) Then
			Continue;
		EndIf;
		
		ARAPObjectSettings		= TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
		OrderInvoice_3	= TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders,, False);
		ThisIsOrder			= ParametersStructure.ThisIsOrder;
		IsCatalog		= ParametersStructure.IsCatalog;
		HFCElementName		= ParametersStructure.FormItems.FinancialAccountingGroup;
		ChangesPaymentPlan	= ParametersStructure.ChangesPaymentPlan;
		
		If ThisIsOrder Then
			
			ItemVisibility = (ChangesPaymentPlan 
					Or ParametersStructure.OrderAsAProformaInvoice)
				And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
					Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice"));
					
		ElsIf OrderInvoice_3 Then
			
			ItemVisibility = ChangesPaymentPlan
				And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
					Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")
					Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice"));
					
		ElsIf IsCatalog Then
			ItemVisibility = True;
		Else
			ItemVisibility = ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
				And ChangesPaymentPlan;
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, HFCElementName, "Visible", ItemVisibility);
		
	EndDo;
	
EndProcedure

Procedure SetLBEditingOption(Form, ParametersStructure = Undefined)
	
	If ParametersStructure <> Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(ParametersStructure);
	Else
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray;
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
		
		AvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
		
		AvailabilityParameters.IsCatalog      = ParametersStructure.IsCatalog;
		AvailabilityParameters.ThisIsOrder           = ParametersStructure.ThisIsOrder;
		AvailabilityParameters.OrderAsAProformaInvoice       = ParametersStructure.OrderAsAProformaInvoice;
		AvailabilityParameters.OrderInvoice_3  = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders,, False);
		
		AvailabilityParameters.Contract            = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract,, Undefined);
		AvailabilityParameters.ARAPObjectSettings    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
		
		AvailabilityParameters.NameOfLBElement      = ParametersStructure.FormItems.LineOfBusiness;
		
		LinesOfBusinessServer.SetLBEditingOption(Form, AvailabilityParameters);
		
	EndDo;
	
EndProcedure

Procedure UpdateHyperlinkTextStateOfCalculations(Form) Export
	
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.FormItems.InscriptionCalculations) Then
			Continue;
		EndIf;
		
		ARAPObjectSettings       = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
		ARAPCurrency  = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency);
		InvoiceForOrders    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders, , False);
		OrderBase        = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.OrderBase);
		ChangesCalculations       = ParametersStructure.ChangesPaymentPlan;
		ElementLabelCalculations = ParametersStructure.FormItems.InscriptionCalculations;
		ThisIsOrder              = ParametersStructure.ThisIsOrder;
		IsCatalog         = ParametersStructure.IsCatalog;
		
		OrderList = ARAPAccountingInternal.GetArrayOfOrdersFromTS(Form, ParametersStructure);
		
		If ValueIsFilled(ElementLabelCalculations) Then
			
			Item = Form.Items[ElementLabelCalculations]; // FormField
			
			If ChangesCalculations 
				//Not an order with invoice calculations
				And Not (ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments)
				//Not a contract without a schedule
				And Not (IsCatalog And Not ValueIsFilled(ParametersStructure.ContractSchedule)) Then
					
				If IsCatalog Then
					
					If ParametersStructure.CustomerSettlementDocument Then
						ShippedLine_ = NStr("vi = 'Đã giao';
											|ru = 'Отгружено';
											|en = 'Shipped'; fa = 'ارسال‌شده';
											|it = 'Spedito';
											|pl = 'Wysłano';
											|tr = 'Sevk edildi'");
					Else
						ShippedLine_ = NStr("vi = 'Số lượng đã nhận';
											|ru = 'Поступило';
											|en = 'Received'; fa = 'دریافت‌شده';
											|it = 'Ricevuti';
											|pl = 'Wpłynęło';
											|tr = 'Geldi'");
					EndIf;
					
					MutualSettlementsStatus = ARAPAccountingServer.MutualSettlementsStatus(Form, ParametersStructure);
					AmountOfPayments   = MutualSettlementsStatus.AmountOfPayments;
					PercentageOfPayments = RoundUpPercentages(MutualSettlementsStatus.PercentageOfPayments);
					AmountOfShipments = MutualSettlementsStatus.AmountByShipments + MutualSettlementsStatus.AmountOfDeliveries;
					PercentageOfDeliveryShipment = RoundUpPercentages(MutualSettlementsStatus.PercentageOfShipments + MutualSettlementsStatus.PercentageOfDeliveries);
				
					Calculations = NStr("vi = 'Đã thanh toán';
										|ru = 'Оплачено';
										|en = 'Amount paid'; fa = 'مبلغ پرداخت‌شده';
										|it = 'Pagato';
										|pl = 'Opłacono';
										|tr = 'Ödendi'") + ": " + Format(AmountOfPayments, "NFD=2; NZ=") 
						+ " " + ARAPCurrency + "  " + PercentageOfPayments + "%";
					Item.Title = Calculations + ", " + ShippedLine_ + ": " + Format(AmountOfShipments, "NFD=2; NZ=") 
						+ " " + ARAPCurrency + "  " + PercentageOfDeliveryShipment + "%";
					
				ElsIf ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
					
					MutualSettlementsStatus = ARAPAccountingServer.MutualSettlementsStatus(Form, ParametersStructure);
					PaymentType_ = ParametersStructure.PaymentType_;
					ClosingBalance = MutualSettlementsStatus.DebtAmount;
					If ClosingBalance < 0  Then
						BalanceText = NStr("vi = 'đã thanh toán';
											|ru = 'оплачено';
											|en = 'paid'; fa = 'paid';
											|it = 'pagato';
											|pl = 'opłacono';
											|tr = 'ödendi'");
						ClosingBalance = - ClosingBalance;
					ElsIf PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then 
						BalanceText = NStr("vi = 'nợ phải thu khách hàng';
											|ru = 'долг клиента';
											|en = 'customer debt'; fa = 'customer debt';
											|it = 'debito del cliente';
											|pl = 'dług klienta';
											|tr = 'müşteri borcu'");
					Else
						BalanceText = NStr("vi = 'nợ phải trả nhà cung cấp';
											|ru = 'долг поставщику';
											|en = 'accounts payable to the vendor'; fa = 'accounts payable to the vendor';
											|it = 'debito verso il fornitore';
											|pl = 'dług wobec dostawcy';
											|tr = 'tedarikçi borç hesabı'");
					EndIf;
					Item.Title = NStr("vi = 'Tính toán theo hợp đồng';
										|ru = 'Расчеты по договору';
										|en = 'AR/AP under contract'; fa = 'دریافتنی/پرداختنی تحت قرارداد';
										|it = 'Regolazioni dei conti per il contratto';
										|pl = 'Rozliczenia kontraktowe';
										|tr = 'Sözleşme kapsamında mutabakat işlemleri'") + ": " + BalanceText 
						+ " " + Format(ClosingBalance, "NFD=2; NZ=0,00;") + " " + ARAPCurrency;
				ElsIf ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice And ThisIsOrder Then
					Item.Title = NStr("vi = 'Hạch toán theo hợp đồng và hóa đơn';
										|ru = 'Расчеты по договору и накладным';
										|en = 'AR/AP accounting under the contract and invoices'; fa = 'AR/AP accounting under the contract and invoices';
										|it = 'Calcoli per contratto e fatture';
										|pl = 'Rozliczenia według kontraktów i faktur';
										|tr = 'Sözleşme ve irsaliye mutabakatları'");
				Else
					
					MutualSettlementsStatus = ARAPAccountingServer.MutualSettlementsStatus(Form, ParametersStructure);
					AmountOfPayments   = Max(0, MutualSettlementsStatus.AmountOfPayments);
					PercentageOfPayments = Max(0, RoundUpPercentages(MutualSettlementsStatus.PercentageOfPayments));
					
					If ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders And InvoiceForOrders And ValueIsFilled(OrderBase)
						Or ThisIsOrder Then
						Item.Title = NStr("vi = 'Đã trả theo đơn hàng:';
											|ru = 'Оплачено по заказу:';
											|en = 'Amount paid:'; fa = 'Amount paid:';
											|it = 'Pagato per l''ordine';
											|pl = 'Opłacono wg zamówienia:';
											|tr = 'Siparişe göre ödendi:'") + " " + Format(AmountOfPayments, "NFD=2; NZ=") + " " + ARAPCurrency + " " + PercentageOfPayments + "%";
					ElsIf OrderList.Count() > 1 And ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders Then
						Item.Title = NStr("vi = 'Thanh toán cho đơn hàng (';
											|ru = 'Расчеты по заказам (';
											|en = 'Settlements on orders ('; fa = 'Settlements on orders (';
											|it = 'Pagamenti per gli ordini (';
											|pl = 'Rozliczenia wg zamówień (';
											|tr = 'Siparişlere göre ödendi ('")+ String(OrderList.Count()) + ")";
					Else
						Item.Title = NStr("vi = 'Đã thanh toán';
											|ru = 'Оплачено';
											|en = 'Amount paid'; fa = 'مبلغ پرداخت‌شده';
											|it = 'Pagato';
											|pl = 'Opłacono';
											|tr = 'Ödendi'") + ": " + Format(AmountOfPayments, "NFD=2; NZ=") + " " + ARAPCurrency + " " + PercentageOfPayments + "%";
					EndIf;
				
				EndIf;
				TMCommonUseClientServer.SetFormItemProperty(Form.Items, ElementLabelCalculations, "Visible", True);
			ElsIf IsCatalog And ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice And NewOnlineARAPAccounting Then
				
				If ParametersStructure.CustomerSettlementDocument Then
					ShippedLine_ = NStr("vi = 'Đã giao';
										|ru = 'Отгружено';
										|en = 'Shipped'; fa = 'ارسال‌شده';
										|it = 'Spedito';
										|pl = 'Wysłano';
										|tr = 'Sevk edildi'");
				Else
					ShippedLine_ = NStr("vi = 'Số lượng đã nhận';
										|ru = 'Поступило';
										|en = 'Received'; fa = 'دریافت‌شده';
										|it = 'Ricevuti';
										|pl = 'Wpłynęło';
										|tr = 'Geldi'");
				EndIf;
				
				MutualSettlementsStatus = ARAPAccountingServer.MutualSettlementsStatus(Form, ParametersStructure);
				AmountOfPayments   = MutualSettlementsStatus.AmountOfPayments;
				PercentageOfPayments = RoundUpPercentages(MutualSettlementsStatus.PercentageOfPayments);
				AmountOfShipments = MutualSettlementsStatus.AmountByShipments + MutualSettlementsStatus.AmountOfDeliveries;
				PercentageOfDeliveryShipment = RoundUpPercentages(MutualSettlementsStatus.PercentageOfShipments + MutualSettlementsStatus.PercentageOfDeliveries);
			
				Calculations = NStr("vi = 'Đã thanh toán';
									|ru = 'Оплачено';
									|en = 'Amount paid'; fa = 'مبلغ پرداخت‌شده';
									|it = 'Pagato';
									|pl = 'Opłacono';
									|tr = 'Ödendi'") + ": " + Format(AmountOfPayments, "NFD=2; NZ=") 
					+ " " + ARAPCurrency + ?(ChangesCalculations, "  " + PercentageOfPayments + "%", "");
				Item.Title = Calculations + ", " + ShippedLine_ + ": " + Format(AmountOfShipments, "NFD=2; NZ=") 
					+ " " + ARAPCurrency + ?(ChangesCalculations, "  " + PercentageOfDeliveryShipment + "%", "");
				TMCommonUseClientServer.SetFormItemProperty(Form.Items, ElementLabelCalculations, "Visible", True);
			Else
				TMCommonUseClientServer.SetFormItemProperty(Form.Items, ElementLabelCalculations, "Visible", False);
			EndIf;
		
			If ParametersStructure.CustomerSettlementDocument Then
				Item.Enabled = AccessRight("Use", Metadata.Reports.CustomerARAPOpenItems24);
			ElsIf ParametersStructure.DocumentOfSettlementsWithSuppliers Then
				Item.Enabled = AccessRight("Use", Metadata.Reports.VendorARAPOpenItems24);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Rounds up the percentages of payment, shipment
//
// Parameters:
//	RoundedNumber - Number - to round a number.
//
// Returns:
//  Number - an integer number of percentages
//
Function RoundUpPercentages(RoundedNumber)
	
	If RoundedNumber > 99
		And RoundedNumber < 100 Then
		Result = 99;
	ElsIf RoundedNumber > 0
		And RoundedNumber < 1 Then
		Result = 1;
	Else
		Result = Round(RoundedNumber);
	EndIf;
	
	Return Result;
	
EndFunction

//Clears the payment transcript
Procedure ClearPaymentDecryption(Object, ParametersStructure)
	
	If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		Return;
	EndIf;
	
	ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
	
	If ParametersStructure.ThisIsSalePurchase Then
		ARAPDetails.Clear();
	Else
		
		ThereIsPaymentBasis = ARAPDetails.Count() > 0 
			And CommonClientServer.HasAttributeOrObjectProperty(ARAPDetails[0],"PaymentPurpose");
		
		For Each Page1 In ARAPDetails Do
			Page1.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
			If ThereIsPaymentBasis Then
				Page1.PaymentPurpose = Undefined;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure ClearObjectAndAmountOfPaymentDecryption(Object, ParametersStructure, SavedCalculationObjects = Undefined)
	
	If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		Return;
	EndIf;
	
	ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
	For Each Page1 In ARAPDetails Do
		If SavedCalculationObjects <> Undefined
			And SavedCalculationObjects.Find(Page1.ARAPObject) <> Undefined Then
			Continue;
		EndIf;
		Page1.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		Page1.AmountARAP = 0;
		If CommonClientServer.HasAttributeOrObjectProperty(Page1, "ARAPCurrency") Then
			Page1.ARAPCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
		EndIf
	EndDo;
	
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		UpdateDistributedDecryptionAmount(Object);
	EndIf;
	
EndProcedure

Function ArrayOfParameterStructuresByBankingDetails(ParametersArray, Val AttributesNames)
	If TypeOf(AttributesNames) = Type("Array") Then
		ArrayOfPropsNames = AttributesNames;
	Else
		ArrayOfPropsNames = New Array;
		ArrayOfPropsNames.Add(AttributesNames);
	EndIf;
	Result = New Array;
	For Each ParametersStructure In ParametersArray Do
		ArrayOfFoundProps = New Array;
		For Each AttributeName In ArrayOfPropsNames Do
			AttributesOfMechanism = ParametersStructure.DetailsUsed["Object."+AttributeName];
			If AttributesOfMechanism <> Undefined Then
				For Each Attribute In AttributesOfMechanism Do
					ArrayOfFoundProps.Add(Attribute);
				EndDo;
			EndIf;
		EndDo;
		If ArrayOfFoundProps.Count() > 0 Then
			ResultStructure1 = New Structure;
			ResultStructure1.Insert("ParametersStructure", ParametersStructure);
			ResultStructure1.Insert("DetailsUsed", ArrayOfFoundProps);
			Result.Add(ResultStructure1);
		EndIf;
	EndDo;
	Return Result;
EndFunction

//Clears certain fields of the stages of the payment schedule.
Procedure ClearPaymentScheduleStageFields(Form, ParametersStructure, ArrayOfCleaningFields)
	
	PaymentScheduleSteps = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps);
	
	If PaymentScheduleSteps = Undefined 
		Or PaymentScheduleSteps.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfAvailableFields = New Array;
	For Each Field In ArrayOfCleaningFields Do
		If CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0], Field) Then
			ArrayOfAvailableFields.Add(Field);
		EndIf;
	EndDo;
	
	For Each Page1 In PaymentScheduleSteps Do
		For Each Field In ArrayOfAvailableFields Do
			Page1[Field] = 0;
		EndDo;
	EndDo;
	
EndProcedure

Function SettlementObjectsAvailableByOrganization(Object, ParametersStructure)
	
	If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		Return Undefined;
	EndIf;
	
	ArrayOfCalculationObjects_ = New Array;
	ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
	For Each Page1 In ARAPDetails Do
		ArrayOfCalculationObjects_.Add(Page1.ARAPObject);
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ARAPObjects", ArrayOfCalculationObjects_);
	Query.SetParameter("Organization", TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization));
	Query.Text = 
		"SELECT
		|	ARAPObjects.Ref AS Ref
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|		INNER JOIN Catalog.CounterpartyContracts.BranchOffices_ AS CounterpartyContractsBranchOffices_
		|		ON ARAPObjects.Contract = CounterpartyContractsBranchOffices_.Ref
		|WHERE
		|	ARAPObjects.Ref IN(&ARAPObjects)
		|	AND CounterpartyContractsBranchOffices_.Ref.CentralizedContract
		|	AND (ARAPObjects.Organization = &Organization
		|			OR CounterpartyContractsBranchOffices_.Ref.Organization = &Organization
		|			OR CounterpartyContractsBranchOffices_.Organization = &Organization
		|				AND (CounterpartyContractsBranchOffices_.Ref.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed
		|					OR ARAPObjects.Organization = CounterpartyContractsBranchOffices_.Ref.Organization))
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Ref AS Ref
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Ref IN(&ARAPObjects)
		|	AND ARAPObjects.Organization.TransactionsUsingParentCompanyAreAllowed
		|	AND (ARAPObjects.Organization.ParentCompany = &Organization
		|		OR ARAPObjects.Organization = &Organization)";
	Selection = Query.Execute().Select();
	ArrayOfCalculationObjects_.Clear();
	While Selection.Next() Do
		ArrayOfCalculationObjects_.Add(Selection.Ref);
	EndDo; 
	
	Return ArrayOfCalculationObjects_;
	
EndFunction

// Checks whether the notification in the form is an event for changing payment documents.
//
// Parameters:
//   EventName - String - name of the event from the procedure in the "message Processing" form.
//
// Returns:
//   Boolean - True if the notification is a payment.
//
Function ChangedPaymentDocumentsForCustomers(EventName) Export
	
	Return
		EventName = "Write_PaymentCardTransaction"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_ARAPSettlement"
		Or EventName = "Write_DebtCancellation";
	
EndFunction

// Checks whether the notification in the form is an event for changing payment documents.
//
// Parameters:
//   EventName - String - name of the event from the procedure in the "message Processing" form.
//
// Returns:
//   Boolean - True if the notification is a payment.
//
Function SupplierPaymentDocumentsChanged(EventName) Export
	
	Return
		EventName = "Write_ExpenseReport"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_ARAPSettlement"
		Or EventName = "Write_DebtCancellation";
	
EndFunction

#EndRegion