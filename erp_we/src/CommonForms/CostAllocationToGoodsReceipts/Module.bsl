
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	NameOfWeightUnitOfMeasure = String(Constants.UnitOfMeasureForWeight.Get());
	NameOfVolumeUnitOfMeasure = String(Constants.UnitOfMeasureForVolume.Get());
	
	If Parameters.Property("Currency") Then
		Currency = Parameters.Currency;
	Else
		Currency = Constants.ManagementAccountingCurrency.Get();
	EndIf;
	
	SetFieldHeaders();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("TableOfRows") Then
		FillInDocumentDetails();
	EndIf;
	
	EstablishDistributionRule();
	
	If GetFunctionalOption("BaseVersion") Then
		ThisForm.Title = NStr("vi = 'Phân bổ chi phí cho giá vốn hàng hóa';
								|ru = 'Распределение расходов на себестоимость товаров';
								|en = 'Expense allocation to inventory costs'; fa = 'تسهیم هزینه به بهای موجودی';
								|it = 'Distribuzione delle spese per il costo di produzione delle merci';
								|pl = 'Przydział kosztów na koszty własne towarów';
								|tr = 'Ürün maliyetlerine giderlerin dağıtımı'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RecalculateRemainderToDistribution();
	CalculateTotals_1();
	CheckFillingOfCoefficients();
	
EndProcedure

&AtClient
Procedure DocumentsListOnChange(Item)
	RecalculateRemainderToDistribution();
	CalculateTotals_1();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllocationOptionOnChange(Item)
	CheckFillingOfCoefficients();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListDocumentOnChange(Item)
	Result = FillInInformationFields(Items.DocumentsList.CurrentData.DimensionOfExpenses);
	If ValueIsFilled(Result) Then
		FillPropertyValues(Items.DocumentsList.CurrentData, Result);
		
		TSRow = Items.DocumentsList.CurrentData;
		TSRow.Count = Count;
		TSRow.Content = Content;
		TSRow.VATRate = VATRate;
		TSRow.Department = Department;
		TSRow.ExpenseItem = ExpenseItem;
		
		RecalculateRemainderToDistribution();
		CalculateTotals_1();
		CheckFillingOfCoefficients();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	If RemainsToAllocate <> 0 Then
		Message = New UserMessage();
		Message.Text = NStr("vi = 'Cần phân bổ thêm cho chứng từ tiếp nhận';
							|ru = 'Необходимо дораспределить на документы поступления';
							|en = 'Finish allocating to receipt documents'; fa = 'Finish allocating to receipt documents';
							|it = 'È necessario distribuire nei documenti di versamento';
							|pl = 'Należy przydzielić do dokumentów wpływu';
							|tr = 'Giriş ​​belgelerine tekrar dağıtmak gereklidir'") + " " + RemainsToAllocate + " " + Currency;
		Message.Message();
	Else
		Close(PutResultInTemporaryStorage());
	EndIf;
EndProcedure

&AtClient
Procedure ShowAllocationBase(Command)
	DocumentsArray = New ValueList();
	For Each CurRow In DocumentsList Do
		DocumentsArray.Add(CurRow.DimensionOfExpenses);
	EndDo;
	
	OpeningParameters = New Structure();
	OpeningParameters.Insert("Filter", New Structure("DocumentsArray", DocumentsArray));
	OpeningParameters.Insert("VariantKey", "WorkingWithContextStrings");
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpeningParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	OpenForm("Report.ReceiptDrillDownByItems.Form", OpeningParameters);
EndProcedure

&AtClient
Procedure ShowEmptyLines(Command)
	DocumentsArray = New ValueList();
	For Each CurRow In DocumentsList Do
		DocumentsArray.Add(CurRow.DimensionOfExpenses);
	EndDo;
	
	OpeningParameters = New Structure();
	OpeningParameters.Insert("Filter", New Structure("DocumentsArray", DocumentsArray));
	OpeningParameters.Insert("VariantKey", "UnfilledWeightVolumeInReceiptsContextual");
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpeningParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	OpenForm("Report.ReceiptDrillDownByItems.Form", OpeningParameters);
EndProcedure

&AtClient
Procedure Allocate(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"CommonForm.CostAllocationToGoodsReceipts.Command.Allocate");
	
	If AllocatedAccordingToRule = "ByCount" Then
		Total = TotalQuantity;
		CoefficientName = "FactorQuantity";
		AllocationComment = NStr("vi = 'Đã phân bổ số tiền %AmountDistributed% (%Currency%) cho %RowsCount% tỷ lệ với số lượng trong hóa đơn';
								|ru = 'Распределена сумма %AmountDistributed% (%Currency%) на %RowsCount% пропорционально количеству накладной';
								|en = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice quantity'; fa = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice quantity';
								|it = 'Importo distribuito %AmountDistributed% (%Currency%) in %RowsCount% in proporzione alla quantità della lettera di vettura';
								|pl = 'Przydzielona kwota %AmountDistributed% (%Currency%) na %RowsCount% jest proporcjonalna do ilości w liście przewozowym';
								|tr = '%AmountDistributed% (%Currency%) tutar irsaliye miktarına %RowsCount% orantılı olarak dağıtıldı'");
	ElsIf AllocatedAccordingToRule = "ByWeight" Then
		Total = TotalWeight_;
		CoefficientName = "FactorWeight";
		AllocationComment = NStr("vi = 'Đã phân bổ số tiền %AmountDistributed% (%Currency%) cho %RowsCount% tỷ lệ với trọng lượng trong hóa đơn';
								|ru = 'Распределена сумма %AmountDistributed% (%Currency%) на %RowsCount% пропорционально весу накладной';
								|en = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice weight'; fa = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice weight';
								|it = 'Importo distribuito %AmountDistributed% (%Currency%) in %RowsCount% in proporzione al peso della lettera di vettura';
								|pl = 'Przydzielona kwota %AmountDistributed% (%Currency%) na %RowsCount% jest proporcjonalna do wagi w liście przewozowym';
								|tr = '%AmountDistributed% (%Currency%) tutar irsaliye ağırlığına%RowsCount% orantılı olarak dağıtıldı'");
	ElsIf AllocatedAccordingToRule = "ByVolume" Then
		Total = TotalVolume;
		CoefficientName = "FactorVolume";
		AllocationComment = NStr("vi = 'Đã phân bổ số tiền %AmountDistributed% (%Currency%) cho %RowsCount% tỷ lệ với khối lượng trong hóa đơn';
								|ru = 'Распределена сумма %AmountDistributed% (%Currency%) на %RowsCount% пропорционально объему накладной';
								|en = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice volume'; fa = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice volume';
								|it = 'Importo distribuito %AmountDistributed% (%Currency%) in %RowsCount% in proporzione al volume della lettera di vettura';
								|pl = 'Przydzielona kwota %AmountDistributed% (%Currency%) na %RowsCount% jest proporcjonalna do objętości w liście przewozowym';
								|tr = '%AmountDistributed% (%Currency%) tutar irsaliye hacmine%RowsCount% orantılı olarak dağıtıldı'");
	Else
		Total = TotalAmount;
		CoefficientName = "FactorAmount";
		AllocationComment = NStr("vi = 'Đã phân bổ số tiền %AmountDistributed% (%Currency%) cho %RowsCount% tỷ lệ với giá trị trong hóa đơn';
								|ru = 'Распределена сумма %AmountDistributed% (%Currency%) на %RowsCount% пропорционально сумме накладной';
								|en = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice amount'; fa = 'Amount %AmountDistributed% (%Currency%) is allocated to %RowsCount% in proportion to the invoice amount';
								|it = 'Importo distribuito %AmountDistributed% (%Currency%) in %RowsCount% in proporzione all''importo della lettera di vettura';
								|pl = 'Przydzielona kwota %AmountDistributed% (%Currency%) na %RowsCount% jest proporcjonalna do kwoty w liście przewozowym';
								|tr = '%AmountDistributed% (%Currency%) tutar irsaliye tutarına%RowsCount% orantılı olarak dağıtıldı'");
	EndIf;
	
	AllocationComment = StrReplace(AllocationComment, "%AmountDistributed%", AmountForAllocation);
	AllocationComment = StrReplace(AllocationComment, "%Currency%", Currency);
	RowsCount = DocumentsList.Count();
	If RowsCount = 1 Then
		 TextNumberOfLines = "" + RowsCount + " string ";
	ElsIf RowsCount > 1 And RowsCount < 5 Then
		 TextNumberOfLines = "" + RowsCount + " rows ";
	Else
		 TextNumberOfLines = "" + RowsCount + " lines ";
	EndIf;
	AllocationComment = StrReplace(AllocationComment, "%RowsCount%", TextNumberOfLines);
	
	ForAllocation = AmountForAllocation;
	For Each String In DocumentsList Do
		If Total * String[CoefficientName] = 0 Then
			To_Write_Off = 0;
		Else
			To_Write_Off = Round(AmountForAllocation / Total * String[CoefficientName], 2, RoundMode.Round15as20);
		EndIf;
		String.AllocationComment = AllocationComment;
		If To_Write_Off > ForAllocation Then
			String.Sum = ForAllocation;
			ForAllocation = 0;
			Break;
		Else
			String.Sum = To_Write_Off;
			ForAllocation = ForAllocation - To_Write_Off;
		EndIf;
	EndDo;
	If ForAllocation <> 0
		And ForAllocation <> AmountForAllocation 
	Then
		String.Sum = String.Sum + ForAllocation;
	EndIf;
	
	RecalculateRemainderToDistribution();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFieldHeaders()

	TMCommonUseClientServer.SetFormItemProperty(Items, "Currency",
				"Title", Currency);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CurrencyNotDistributed",
				"Title", Currency);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DocumentsListSum",
				"Title", NStr("vi = 'Tổng số';
								|ru = 'Сумма';
								|en = 'Amount'; fa = 'مبلغ';
								|it = 'Importo';
								|pl = 'Amount';
								|tr = 'Tutar'") +" (" + CurrencyOfMan + ")");
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListOfDocumentsWeight",
				"Title", NStr("vi = 'Trọng lượng';
								|ru = 'Вес';
								|en = 'Weight'; fa = 'وزن';
								|it = 'Peso';
								|pl = 'Waga';
								|tr = 'Ağırlık'") +" (" + NameOfWeightUnitOfMeasure + ")");
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListOfDocumentsVolume",
				"Title", NStr("vi = 'Khối lượng';
								|ru = 'Объем';
								|en = 'Volume'; fa = 'حجم';
								|it = 'Volume';
								|pl = 'Objętość';
								|tr = 'Hacim'") +" (" + NameOfVolumeUnitOfMeasure + ")");

EndProcedure

&AtServer
Procedure FillInDocumentDetails()
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	Rows.DocumentRowNumber AS DocumentRowNumber,
	|	Rows.DimensionOfExpenses AS Ref,
	|	Rows.Content        AS Content,
	|	Rows.Count        AS Count,
	|	Rows.Sum             AS Sum,
	|	Rows.VATRate         AS VATRate,
	|	Rows.Department     AS Department,
	|	Rows.ExpenseItem    AS ExpenseItem
	|INTO TTArrayOfStrings
	|FROM
	|	&RowsArray AS Rows
	|WHERE
	|	VALUETYPE(Rows.DimensionOfExpenses) 
	|		= TYPE(Document.VendorInvoice)
	|;
	|////////////////////////////
	|SELECT
	|	Rows.DocumentRowNumber AS DocumentRowNumber,
	|	Rows.Ref            AS Ref,
	|	Rows.Content        AS Content,
	|	Rows.Count        AS Count,
	|	Rows.Sum             AS Sum,
	|	Rows.VATRate         AS VATRate,
	|	Rows.Department     AS Department,
	|	Rows.ExpenseItem    AS ExpenseItem
	|INTO RowsArray
	|FROM
	|	TTArrayOfStrings AS Rows
	|WHERE
	|	VALUETYPE(Rows.Ref) 
	|		= TYPE(Document.VendorInvoice)
	|;
	|////////////////////////////
	|SELECT
	|	SUM(Rows.Sum) AS Sum
	|FROM
	|	RowsArray AS Rows
	|;
	|////////////////////////////
	|SELECT TOP 1
	|	Rows.Content     AS Content,
	|	Rows.Count     AS Count,
	|	Rows.VATRate      AS VATRate,
	|	Rows.Department  AS Department,
	|	Rows.ExpenseItem AS ExpenseItem
	|INTO ExpenseContent
	|FROM
	|	RowsArray AS Rows
	|WHERE
	|	Rows.Content <> UNDEFINED
	|;
	|////////////////////////////
	|SELECT TOP 1
	|	Rows.Content     AS Content,
	|	Rows.Count     AS Count,
	|	Rows.VATRate      AS VATRate,
	|	Rows.Department  AS Department,
	|	Rows.ExpenseItem AS ExpenseItem
	|FROM
	|	ExpenseContent AS Rows
	|;
	|////////////////////////////
	|SELECT
	|	Rows.DocumentRowNumber AS DocumentRowNumber
	|FROM TTArrayOfStrings AS Rows
	|WHERE
	|	Rows.Ref = VALUE(Document.VendorInvoice.EmptyRef)
	|;
	|////////////////////////////
	|SELECT
	|	Rows.DocumentRowNumber                     AS DocumentRowNumber,
	|	Cost_.Recorder                       AS DimensionOfExpenses,
	|	Cost_.Organization                       AS Organization,
	|	Cost_.AccountingDimensionByPartners.Partner AS Partner,
	|	Text.Content                                AS Content,
	|	Text.Count                                AS Count,
	|	Text.VATRate                                 AS VATRate,
	|	Text.Department                             AS Department,
	|	Text.ExpenseItem                            AS ExpenseItem,
	|	SUM(Cost_.Count)                 AS FactorQuantity,
	|	SUM(Cost_.Cost)                  AS FactorAmount,
	|	SUM(Cost_.Count * &QueryTextPackageWeight)   	  AS FactorWeight,
	|	SUM(Cost_.Count * &QueryTextPackageVolume) 	  AS FactorVolume,
	|	MAX(CASE WHEN &QueryTextPackageWeight = 0
	|		THEN 1
	|		ELSE 0
	|	END)                                        AS ErrorFactorWeight,
	|	MAX(CASE WHEN &QueryTextPackageVolume = 0
	|		THEN 1
	|		ELSE 0
	|	END)                                        AS ErrorFactorVolume
	|FROM
	|	RowsArray AS Rows
	|		INNER JOIN AccumulationRegister.InventoryCost AS Cost_
	|		ON Rows.Ref = Cost_.Recorder
	|		
	|		LEFT JOIN ExpenseContent AS Text
	|		ON TRUE
	|
	|GROUP BY
	|	Rows.DocumentRowNumber,
	|	Cost_.Recorder,
	|	Cost_.Period,
	|	Cost_.Organization,
	|	Cost_.AccountingDimensionByPartners.Partner,
	|	Text.Content,
	|	Text.Count,
	|	Text.VATRate,
	|	Text.Department,
	|	Text.ExpenseItem
	|
	|HAVING
	|	SUM(Cost_.Count) <> 0
	|
	|ORDER BY
	|	DocumentRowNumber
	|";
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackageWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
									"Cost_.ItemsLocationAttributes.Products.UnitOfMeasure",
									"Cost_.ItemsLocationAttributes.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextPackageVolume",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
									"Cost_.ItemsLocationAttributes.Products.UnitOfMeasure",
									"Cost_.ItemsLocationAttributes.Products"));
	
	Query.Text = QueryText;
	
	Query.SetParameter("RowsArray", GetFromTempStorage(Parameters.TableOfRows));
	Result = Query.ExecuteBatch();
	
	Selection = Result[2].Select();
	Selection.Next();
	AmountForAllocation = Selection.Sum;
	
	Selection = Result[4].Select();
	Selection.Next();
	
	Content = Selection.Content;
	Count = Selection.Count;
	VATRate = Selection.VATRate;
	Department = Selection.Department;
	ExpenseItem = Selection.ExpenseItem;
	
	LinesToDelete.Load(Result[5].Unload());
	DocumentsList.Load(Result[6].Unload());
	
EndProcedure

&AtServer
Procedure EstablishDistributionRule() 
	DistributionRuleInArticle = Common.ObjectAttributeValue(ExpenseItem, "CostAllocationRuleToProcuctCost");
	If DistributionRuleInArticle = Enums.RulesOfAllocationForInventoryCost.InProportionToProductQuantity
		Or DistributionRuleInArticle = Enums.RulesOfAllocationForInventoryCost.EmptyRef()
	Then
		AllocatedAccordingToRule = "ByCount";
	ElsIf DistributionRuleInArticle = Enums.RulesOfAllocationForInventoryCost.InProportionToProductCost Then
		AllocatedAccordingToRule = "ByAmount";
	ElsIf DistributionRuleInArticle = Enums.RulesOfAllocationForInventoryCost.InProportionToItemsWeight Then
		AllocatedAccordingToRule = "ByWeight";
	ElsIf DistributionRuleInArticle = Enums.RulesOfAllocationForInventoryCost.InProportionToItemsVolume Then
		AllocatedAccordingToRule = "ByVolume";
	EndIf;
EndProcedure

&AtClient
Procedure CalculateTotals_1()
	TotalAmount = DocumentsList.Total("FactorAmount");
	TotalQuantity = DocumentsList.Total("FactorQuantity");
	TotalWeight_ = DocumentsList.Total("FactorWeight");
	TotalVolume = DocumentsList.Total("FactorVolume");
EndProcedure

&AtClient
Procedure RecalculateRemainderToDistribution()
	RemainsToAllocate = AmountForAllocation - DocumentsList.Total("Sum")
EndProcedure

&AtServer
Function PutResultInTemporaryStorage()
	
	UnloadedFields = "
	|DocumentRowNumber, 
	|Sum,
	|Content,
	|AllocationComment,
	|Count,
	|VATRate,
	|Department,
	|DimensionOfExpenses,
	|ExpenseItem
	|";
	ClosingParameters = New Structure("AddressInTempStorage, LinesToDelete",
						PutToTempStorage(DocumentsList.Unload(,UnloadedFields), AddressInTempStorage),
						PutToTempStorage(LinesToDelete.Unload(,"DocumentRowNumber"), AddressOfLinesForRemoval));
	Return ClosingParameters;

EndFunction

&AtServer
Function FillInInformationFields(Data)
	
	QueryText = 
	"SELECT
	|	ISNULL(Register3.Partner, UNDEFINED) AS Partner,
	|	SUM(Cost_.Count) AS FactorQuantity,
	|	SUM(Cost_.Cost)  AS FactorAmount,
	|	SUM(Cost_.Count
	|		* ISNULL(&QueryTextPackageWeight, 0)
	|	)                               AS FactorWeight,
	|	SUM(Cost_.Count 
	|		* ISNULL(&QueryTextPackageVolume, 0)
	|	)                               AS FactorVolume,
	|	MAX(CASE WHEN &QueryTextPackageWeight = 0
	|		THEN 1
	|		ELSE 0
	|	END)                          AS ErrorFactorWeight,
	|	MAX(CASE WHEN &QueryTextPackageVolume = 0
	|		THEN 1
	|		ELSE 0
	|	END)                          AS ErrorFactorVolume
	|FROM
	|	AccumulationRegister.InventoryCost AS Cost_
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = Cost_.Recorder
	|		AND Register3.Organization = Cost_.Organization
	|		AND NOT Register3.AdditionalRecord
	|WHERE
	|	Cost_.Recorder = &Ref
	|GROUP BY
	|	Cost_.Recorder,
	|	ISNULL(Register3.Partner, UNDEFINED)
	|";
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackageWeight", 
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
									"Cost_.ItemsLocationAttributes.Products.UnitOfMeasure",
									"Cost_.ItemsLocationAttributes.Products"));
		
	QueryText = StrReplace(QueryText,
								"&QueryTextPackageVolume", 
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
									"Cost_.ItemsLocationAttributes.Products.UnitOfMeasure",
									"Cost_.ItemsLocationAttributes.Products"));
	
	Query = New Query(QueryText);
	
	Query.SetParameter("Ref", Data);
	
	Result = Query.Execute().Unload();
	If Result.Count() <> 0 Then
		ResultString1 = New Structure("Partner,
		|FactorQuantity,
		|FactorAmount,
		|FactorWeight,
		|FactorVolume,
		|ErrorFactorWeight,
		|ErrorFactorVolume
		|");
		FillPropertyValues(ResultString1, Result[0]);
	Else
		ResultString1 = Undefined;
	EndIf;
	
	Return ResultString1;

EndFunction

&AtClient
Procedure CheckFillingOfCoefficients()
	If DocumentsList.Count() = 0 Then
		Items.WarningGroup.Visible = False;
		Return;
	EndIf;
	If AllocatedAccordingToRule = "ByCount" Then
		HasErrors = ?(DocumentsList.Total("FactorQuantity") = 0, True, False);
		Items.DocumentsListErrorFactorWeight.Visible = False;
		Items.DocumentsListErrorFactorVolume.Visible = False;
	ElsIf AllocatedAccordingToRule = "ByWeight" Then
		HasErrors = ?(DocumentsList.Total("ErrorFactorWeight") <> 0, True, False);
		Items.DocumentsListErrorFactorWeight.Visible = True;
		Items.DocumentsListErrorFactorVolume.Visible = False;
		Items.WarningTheDecorationText.Title = NStr("vi = 'Trong chứng từ tiếp nhận có các dòng chưa điền trọng lượng. Không thể phân bổ cho các dòng này.';
													|ru = 'В документах поступления есть строки с незаполненным весом. Распределение не будет произведено на данные строки.';
													|en = 'There are lines with unfilled weight in the receipt documents. Allocation will not be made for these lines.'; fa = 'There are lines with unfilled weight in the receipt documents. Allocation will not be made for these lines.';
													|it = 'Nei documenti di versamento ci sono delle righe con peso non compilato. Non sarà effettuata la distribuzione per tali righe.';
													|pl = 'W dokumentach wpływu istnieją wiersze z niewypełnioną wagą. Przydział nie zostanie wykonany dla tych wierszy.';
													|tr = 'Giriş belgelerinde ağırlığı doldurulmayan satırlar var. Bu satırlara dağıtım yapılmayacaktır.'");
	ElsIf AllocatedAccordingToRule = "ByVolume" Then
		HasErrors = ?(DocumentsList.Total("ErrorFactorVolume") <> 0, True, False);
		Items.DocumentsListErrorFactorWeight.Visible = False;
		Items.DocumentsListErrorFactorVolume.Visible = True;
		Items.WarningTheDecorationText.Title = NStr("vi = 'Trong chứng từ tiếp nhận có các dòng chưa điền khối lượng. Không thể phân bổ cho các dòng này.';
													|ru = 'В документах поступления есть строки с незаполненным объемом. Распределение не будет произведено на данные строки.';
													|en = 'There are lines with unfilled volume in the receipt documents. Allocation will not be made for these lines.'; fa = 'There are lines with unfilled volume in the receipt documents. Allocation will not be made for these lines.';
													|it = 'Nei documenti di versamento ci sono delle righe con volume non compilato. Non sarà effettuata la distribuzione per tali righe.';
													|pl = 'W dokumentach wpływu istnieją wiersze z niewypełnioną objętością. Przydział nie zostanie wykonany dla tych wierszy.';
													|tr = 'Giriş belgelerinde hacmi doldurulmayan satırlar var. Bu satırlara dağıtım yapılmayacaktır.'");
	ElsIf AllocatedAccordingToRule = "ByAmount" Then
		HasErrors = ?(DocumentsList.Total("FactorQuantity") = 0, True, False);
		Items.DocumentsListErrorFactorWeight.Visible = False;
		Items.DocumentsListErrorFactorVolume.Visible = False;
	EndIf;
	Items.WarningGroup.Visible = HasErrors;
EndProcedure

#EndRegion
