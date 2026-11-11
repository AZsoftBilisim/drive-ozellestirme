#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.TransferOrder")
		Or TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(FillingData) = Type("DocumentRef.InventoryTransfer")
		Or TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		
		Kind = Enums.PackingListKinds.Incoming;
		
		FillInOnTheBasis(FillingData);
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	If Kind = Enums.PackingListKinds.Outgoing Then
		NotCheckedAttributeArray.Add("Code");
	EndIf;
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.OutputLineNumbers = True;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	ProductsServer.CheckSeriesCompletion(ThisObject, ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PackingList), Cancel);
	PackingListsServer.CheckFillingOfPMWithPackingLists(ThisObject, CheckedAttributes, NotCheckedAttributeArray, Cancel);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not ValueIsFilled(Code) Then
		Code = Documents.PackingList.GetNewCode();
	EndIf;
	
	TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(Goods);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInOnTheBasis(DocumentBasis)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	Goods.Products              AS Products,
	|	Goods.Characteristic            AS Characteristic,
	|	Goods.Package                  AS Package,
	|	Goods.Series                     AS Series,
	|	Goods.BatchesIndicationStatus       AS BatchesIndicationStatus,
	|	SUM(Goods.Count)         AS Count,
	|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	&DataSource AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|	AND (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		OR Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus";
	
	DataSource = "";
	TSName          = "Goods";
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.TransferOrder") Then
		DataSource = Metadata.Documents.TransferOrder.FullName() + "." + TSName;
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.PurchaseOrder") Then
		DataSource = Metadata.Documents.PurchaseOrder.FullName() + "." + TSName;
		QueryText   = RequestTextBasedOnOrderToSupplier();
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.InventoryTransfer") Then
		DataSource = Metadata.Documents.InventoryTransfer.FullName() + "." + TSName;
	Else
		DataSource = Metadata.Documents.VendorInvoice.FullName() + "." + TSName;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DataSource", DataSource);
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	Goods.Load(QueryResult.Unload());
	
EndProcedure

Function RequestTextBasedOnOrderToSupplier()
	
	QueryText =
	"SELECT
	|	Goods.Products              AS Products,
	|	Goods.Characteristic            AS Characteristic,
	|	Goods.Package                  AS Package,
	|	SUM(Goods.Count)         AS Count,
	|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	&DataSource AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|	AND (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		OR Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf