#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Parameters.Organization);
	EnterTheReglUprSeparately = Not (ManagementAccountingCurrency = LocalAccountingCurrency);
	UseSeveralPriceTypes = GetFunctionalOption("UseSeveralPriceTypes");
	ConfigureFormByParameters(Parameters);
	SetVisibility1(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MethodForDeterminingTheCostPriceManuallyOnChange(Item)
	
	SetVisibility1(ThisObject);
	
EndProcedure

&AtClient
Procedure MethodForDeterminingTheCostPriceCurrentDocumentOnChange(Item)
	
	SetVisibility1(ThisObject);
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	FillInAmountsByPriceType();
	
EndProcedure

&AtClient
Procedure FillingDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInAmountsByPriceType();

EndProcedure

&AtClient
Procedure SumManOnChange(Item)
	
	If TaxationType <> PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
		Goods[0].AmountExcludingVAT = Goods[0].AmountIncludingVAT;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkClose(Command)

	ClearMessages();
	If CheckFilling() Then
		MigrateDataToTheDocument();
	EndIf;
		
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetVisibility1(Form)
	
	If Form.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.Manually") Then
		Form.Items.AmountsGroup.CurrentPage = Form.Items.ManualDataGroup;
		ShowAmounts = (Form.Goods.Count() = 1);
		Form.Items.UPRGroup.Visible = ShowAmounts;
		Form.Items.ReglGroup.Visible = ShowAmounts;
	Else
		Form.Items.AmountsGroup.CurrentPage = Form.Items.GroupManuallyEmpty;
	EndIf;

EndProcedure

&AtServer
Procedure FillInAmountsByPriceType()
	
	If Not ValueIsFilled(PriceKind) Or Not ValueIsFilled(FillingDate) Then
		Items.TheInscriptionIsNoPriceOnTheDate.Visible = False;
		Return;
	EndIf;
	
	StructureOfSelectionByTypeOfPrices = New Structure;
	StructureOfSelectionByTypeOfPrices.Insert("Ref", PriceKind);
	PriceIncludesVAT = Catalogs.TypesOfPrices.PriceTypeAndPriceIncludesVATAttributeByDefault(StructureOfSelectionByTypeOfPrices).PriceIncludesVAT;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", PriceIncludesVAT);
	StructureOfRecalculationOfAmount.Insert("VATTaxation", TaxationType);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", FillingDate);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Currency", DocumentCurrency);
	FillParameters.Insert("PriceKind", PriceKind);
	FillParameters.Insert("VATTaxation", TaxationType);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	EnterprisePricesFillingServer.FillInPrices(
		Goods,
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
		
	ConversionFactorOfDocMan = ?(DocumentCurrency = ManagementAccountingCurrency,
			1,
			ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(DocumentCurrency,
				ManagementAccountingCurrency,
				FillingDate));
	ConversionFactorDocLocal = ?(DocumentCurrency = LocalAccountingCurrency,
			1,
			ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(DocumentCurrency,
				LocalAccountingCurrency,
				FillingDate));
	NoPrice = False;
	For Each CurrentRow In Goods Do
		
		AmountExcludingVAT = CurrentRow.AmountIncludingVAT-CurrentRow.VATAmount;
		CurrentRow.AmountIncludingVAT = CurrentRow.AmountIncludingVAT * ConversionFactorOfDocMan;
		CurrentRow.AmountExcludingVAT = AmountExcludingVAT * ConversionFactorOfDocMan;
		CurrentRow.SumCompl = AmountExcludingVAT * ConversionFactorDocLocal;
		CurrentRow.AmountPermanentDifferences = 0;
		CurrentRow.AmountTemporaryDifferences = 0;
		If CurrentRow.Price = 0 Then
			NoPrice = True;
		EndIf;
		
	EndDo;
	
	Items.TheInscriptionIsNoPriceOnTheDate.Visible = NoPrice;
	
EndProcedure

&AtServer
Procedure ConfigureFormByParameters(Var_Parameters)
	
	Organization = Var_Parameters.Organization;
	Partner = Var_Parameters.Partner;
	Contract = Var_Parameters.Contract;
	Terms = Var_Parameters.Terms;
	DocumentCurrency = Var_Parameters.DocumentCurrency;
	TaxationType = Var_Parameters.TaxationType;
	
	If TypeOf(Var_Parameters.RowsOfProductsTable) = Type("Array") Then
		
		If Var_Parameters.RowsOfProductsTable.Count() Then
			FirstRow = Var_Parameters.RowsOfProductsTable[0];
			PriceKind = FirstRow.PriceKind;
			FillingDate = FirstRow.DateOfCostFillingByPriceType;
			CostDefiningMethod = FirstRow.CostDefiningMethod;
		EndIf;
		
		LineNumber = 0;
		For Each CurrentRow In Var_Parameters.RowsOfProductsTable Do
			
			LineNumber = LineNumber + 1;
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, CurrentRow);
			
			NewRow.LineNumber = LineNumber;
			
			If PriceKind <> CurrentRow.PriceKind Then
				PriceKind = Undefined;
			EndIf;
			
			If FillingDate <> CurrentRow.DateOfCostFillingByPriceType Then
				FillingDate = Undefined;
			EndIf;
			
			If CostDefiningMethod <> CurrentRow.CostDefiningMethod Then
				CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"ReglUprGroup",
		"Visible",
		EnterTheReglUprSeparately);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"GroupCost",
		"Visible",
		Not EnterTheReglUprSeparately);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"PriceViewGroup",
		"Visible",
		UseSeveralPriceTypes);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"ManagExcludingVAT",
		"Visible",
		TaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"CostExcludingVAT_",
		"Visible",
		TaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	CalculationOfPermanentAndTemporaryDifferencesIsKept = AccountingPoliciesTaxSettingsLocalization.CalculationOfPermanentAndTemporaryDifferencesIsKept(Var_Parameters.Organization, Var_Parameters.Date);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"PRVRGroup",
		"Visible",
		CalculationOfPermanentAndTemporaryDifferencesIsKept);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"GroupCostOfPRVR",
		"Visible",
		CalculationOfPermanentAndTemporaryDifferencesIsKept 
			And Not TaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"GroupCostPriceWithoutNDSPRR",
		"Visible",
		CalculationOfPermanentAndTemporaryDifferencesIsKept 
			And TaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	If EnterTheReglUprSeparately Then
		If TaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
			ManTitleText = NStr("vi = 'Kế toán quản trị gồm thuế GTGT (%1):';
								|ru = 'Упр. учет с НДС (%1):';
								|en = 'Management accounting including VAT (%1):'; fa = 'Management accounting including VAT (%1):';
								|it = 'Contabilità gestionale con IVA (%1):';
								|pl = 'Ewid. zarz. z VAT (%1):';
								|tr = 'KDV dahil yönetim muhasebesi (%1):'");
			ManTitleTextWithoutVAT = NStr("vi = 'Kế toán quản trị không gồm thuế GTGT (%1):';
											|ru = 'Упр. учет без НДС (%1):';
											|en = 'Management accounting excluding VAT (%1):'; fa = 'Management accounting excluding VAT (%1):';
											|it = 'Contabilità gestionale IVA esclusa (%1):';
											|pl = 'Ewid. zarz. z VAT (%1):';
											|tr = 'KDV hariç yönetim muhasebesi (%1):'");
			Items.LabelUPRWithoutVAT.Title = 
				StringFunctionsClientServer.SubstituteParametersToString(ManTitleTextWithoutVAT, ManagementAccountingCurrency);
		Else
			ManTitleText = NStr("vi = 'Kế toán quản trị (%1):';
								|ru = 'Упр. учет (%1):';
								|en = 'Management accounting (%1):'; fa = 'Management accounting (%1):';
								|it = 'Contabilità gestionale (%1):';
								|pl = 'Ewid. zarz. (%1):';
								|tr = 'Yönetim muhasebesi (%1):'");
		EndIf;
		Items.TheInscriptionUPR.Title = StringFunctionsClientServer.SubstituteParametersToString(ManTitleText, ManagementAccountingCurrency);
		LocalTitleText = NStr("vi = 'Kế toán pháp quy %1 (%2):';
								|ru = 'Регл. учет %1(%2):';
								|en = 'Local accounting %1(%2):'; fa = 'Local accounting %1(%2):';
								|it = 'Contabilità regolamentare %1(%2):';
								|pl = 'Ewid. regl. %1(%2):';
								|tr = 'Yerel muhasebe %1(%2):'");
		Items.LabelRegl.Title = StringFunctionsClientServer.SubstituteParametersToString(
			LocalTitleText,
			?(TaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT, NStr("vi = 'không thuế GTGT';
																			|ru = 'без НДС';
																			|en = 'Excluding VAT'; fa = 'بدون مالیات بر ارزش افزوده';
																			|it = 'IVA esclusa';
																			|pl = 'Netto';
																			|tr = 'KDV hariç'") + " ", ""),
			LocalAccountingCurrency);	
	Else
		HeadingTextCostPrice = NStr("vi = 'Giá vốn gồm thuế GTGT (%1):';
									|ru = 'Себестоимость с НДС (%1):';
									|en = 'Cost including VAT (%1):'; fa = 'Cost including VAT (%1):';
									|it = 'Costi di produzione con IVA (%1):';
									|pl = 'Koszt własny z VAT (%1):';
									|tr = 'KDV dahil maliyet (%1):'");
		TitleTextCostWithoutVAT = NStr("vi = 'Giá vốn không gồm thuế GTGT (%1):';
										|ru = 'Себестоимость без НДС (%1):';
										|en = 'Cost excluding VAT (%1):'; fa = 'Cost excluding VAT (%1):';
										|it = 'Costi di produzione senza IVA (%1):';
										|pl = 'Koszt własny bez VAT (%1):';
										|tr = 'KDV hariç maliyet (%1):'");
		Items.LabelCostPrice.Title = 
				StringFunctionsClientServer.SubstituteParametersToString(HeadingTextCostPrice, ManagementAccountingCurrency);
		Items.LabelCostPriceWithoutVAT.Title = 
				StringFunctionsClientServer.SubstituteParametersToString(TitleTextCostWithoutVAT, ManagementAccountingCurrency);
	EndIf;
		
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not ClosingInProgress And Modified Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
				|ru = 'Данные были изменены. Перенести изменения в документ?';
				|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
				|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
				|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"),
			QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClearMessages();
		If CheckFilling() Then
			ClosingInProgress = True;
			MigrateDataToTheDocument();
		EndIf;
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure MigrateDataToTheDocument()

	Modified = False;
	
	RowsOfProductsTable = New Array;
	
	For Each CurrentRow In Goods Do
		
		RowParameters = TMCommonUseClient.NewElementArrayProducts();
		
		RowParameters.CostDefiningMethod = CostDefiningMethod;
		RowParameters.Id = CurrentRow.Id;
		
		If CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.Manually") Then
			RowParameters.CostPriceKind = PriceKind;
			RowParameters.DateOfCostFillingByPriceType = FillingDate;
			RowParameters.Cost_ = CurrentRow.AmountIncludingVAT;
			RowParameters.CostExcludingVAT_ = CurrentRow.AmountExcludingVAT;
			If Not EnterTheReglUprSeparately Then
				CurrentRow.SumCompl = ?(TaxationType = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT"), 
					CurrentRow.AmountExcludingVAT, CurrentRow.AmountIncludingVAT)
			EndIf;
			RowParameters.CostLocal = CurrentRow.SumCompl;
			RowParameters.CDCost = CurrentRow.AmountPermanentDifferences;
			RowParameters.TDCost = CurrentRow.AmountTemporaryDifferences;
		Else
			RowParameters.CostPriceKind = Undefined;
			RowParameters.DateOfCostFillingByPriceType = Date(1, 1, 1);
			RowParameters.Cost_ = 0;
			RowParameters.CostExcludingVAT_ = 0;
			RowParameters.CostLocal = 0;
			RowParameters.CDCost = 0;
			RowParameters.TDCost = 0;
		EndIf;
		
		RowsOfProductsTable.Add(RowParameters);
		
	EndDo;
	
	ClosingParameters = TMCommonUseClient.NewProductStructure();
	ClosingParameters.RowsOfProductsTable = RowsOfProductsTable;
	Close(ClosingParameters);
						
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

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
	If Item.Name = "sh_ShamsiInput_F_FillingDate" Then
		FillingDateOnChange(Items.FillingDate);
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
