#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array();
	
	If AdditionalProperties.Property("OneItemOfProducts") Then
		If AdditionalProperties.OneItemOfProducts Then
			NotCheckedAttributeArray.Add("PlanAndResearchResult.Products");
			NotCheckedAttributeArray.Add("PlanAndResearchResult.Characteristic");
			NotCheckedAttributeArray.Add("PlanAndResearchResult.NumberOfPackages");
			CheckPlanAndResultOfStudyOfOneGoods(Cancel);
		Else
			CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
			CheckParameters.TSName = "PlanAndResearchResult";

			ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
				ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		EndIf;
	Else
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "PlanAndResearchResult";

		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
				ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.GoodsQualityResearch);

	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.PlanAndResearchResult);
	ProductsServer.CheckSeriesCompletion(ThisObject, ParametersArray, Cancel, NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "Goods_Research";

	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
	ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	If NotCheckedAttributeArray.Find("PlanAndResearchResult.Package") = Undefined Then
		NotCheckedAttributeArray.Add("PlanAndResearchResult.Package");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ThereAreVariances = CalculateDeviation();
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		Else
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
		
		If FillingData.Property("Goods") Then
			
			FillInProductsTable(FillingData.Goods);
			
		EndIf;
		
		InitializeDocumentAfterFillingItOut();
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(RequestForControl) Then
		InformationRegisters.RequestStatesForQualityControl.ReflectStateOfApplications(RequestForControl);
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Control = Enums.QualityControl.Selective;
	InstancesCheckMethod = Enums.CheckOptionsOfResearchCopies.CopyByCopy;
	Completed = False;
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure InitializeDocumentAfterFillingItOut(FillingData = Undefined)
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsQualityResearch));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters["PlanAndResearchResult"]);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters["Goods_Research"]);
	
EndProcedure

Function CalculateDeviation()
	
	Return PlanAndResearchResult.Total("QuantityRejectable") <> 0;
	
EndFunction

#EndRegion

#Region FillType

// Fills in the tabular part of the "Research results plan" of the document "Quality research of goods" based on the transmitted table of goods.
//
// Parameters:
//   TableOfGoods - ValueTable - a table with data on items to fill in the tabular part of the "Research planresult"
Procedure FillInProductsTable(TableOfGoods)
	
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	
	If TableOfGoods.Columns.Find("NumberOfPackages") = Undefined Then
		StructureOfActions.Insert("RecalculateNumberOfPackages");
	EndIf;
	
	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		LineOfATabularSection = PlanAndResearchResult.Add();
		FillPropertyValues(LineOfATabularSection, RowOfProduct);
		LineOfATabularSection.RowID = New UUID;
		
		RowsToProcess.Add(LineOfATabularSection);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		PlanAndResearchResult,
		CachedValues);
	
EndProcedure

#EndRegion

#Region Validation

Procedure CheckPlanAndResultOfStudyOfOneGoods(Cancel)

	If PlanAndResearchResult.Count() <> 0 Then

		TableRowPlanAndResultOfStudy = PlanAndResearchResult[0];

		Template = NStr("vi = 'Chưa điền trường ""%1""';
						|ru = 'Поле ""%1"" не заполнено';
						|en = '""%1"" is required'; fa = '""%1"" is required';
						|it = 'Il campo ""%1"" non è compilato';
						|pl = 'Pole ""%1"" nie jest wypełnione';
						|tr = '""%1"" alanı doldurulmamış'");
		ListOfVerifiedDetails = New Structure("Products, NumberOfPackages",
			"Products", "K toresearch");

		For Each KeyAndValue In ListOfVerifiedDetails Do
			If Not ValueIsFilled(TableRowPlanAndResultOfStudy[KeyAndValue.Key]) Then
				MessageText = StrTemplate(Template, KeyAndValue.Value);
				Common.MessageToUser(MessageText, ThisObject, , , Cancel);
			EndIf;
		EndDo;

		UseCharacteristics = GetFunctionalOption("UseItemVariants");

		If UseCharacteristics And Not ValueIsFilled(TableRowPlanAndResultOfStudy.Characteristic)
			And Catalogs.Products.ItemVariantsAreUsed(
			TableRowPlanAndResultOfStudy.Products) Then
			MessageText = NStr("vi = 'Chưa điền trường ""Đặc tính""';
								|ru = 'Поле ""Характеристика"" не заполнено';
								|en = '""Variant"" is not filled in'; fa = '""Variant"" is not filled in';
								|it = 'Il campo ""Caratteristica"" non è compilato';
								|pl = 'Pole ""Charakterystyka"" nie jest wypełnione';
								|tr = '""Varyant"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, ThisObject, , , Cancel);
		EndIf;

	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf
