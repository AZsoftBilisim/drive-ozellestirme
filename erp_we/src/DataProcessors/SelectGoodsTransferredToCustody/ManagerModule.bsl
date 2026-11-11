#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

//Returns the text of the request for the transferred goods
//
// Returns:
//  String - 
//
Function QueryTextGoodsTransferred() Export

	QueryText =
	"SELECT
	|	InvoiceGoods.LineNumber AS LineNumber,
	|	InvoiceGoods.Products AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.Series AS Series,
	|	InvoiceGoods.Purpose AS Purpose,
	|	InvoiceGoods.CCDNumber AS CCDNumber,
	|	InvoiceGoods.Count AS Count
	|INTO TTGoodsWaybill
	|FROM
	|	&Goods AS InvoiceGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	TTGoodsWaybill.Series AS Series,
	|	FALSE AS DifferentSeriesAccounting,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber,
	|	SUM(TTGoodsWaybill.Count) AS Count
	|INTO InvoiceGoods
	|FROM
	|	TTGoodsWaybill AS TTGoodsWaybill
	|GROUP BY
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	TTGoodsWaybill.Series,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	DimensionKeys.Ref AS Ref
	|INTO DimensionKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|WHERE
	|	DimensionKeys.StorageLocation = &Contract
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3 - Balances as of the document date
	|SELECT ALLOWED
	|	GoodsTransferredBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferredBalance.CCDNumber AS CCDNumber,
	|	GoodsTransferredBalance.CountBalance AS CountBalance
	|INTO GoodsTransferredBalance
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&Period, ItemsLocationAttributes IN
	|		(SELECT
	|			DimensionKeys.Ref
	|		FROM
	|			DimensionKeys AS DimensionKeys)
	|		AND Organization = &Organization) AS GoodsTransferredBalance
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4 - Current Balances
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CountBalance AS CountBalance,
	|	CASE
	|		WHEN GoodsTransferred.CountBalance < 0
	|			THEN -1
	|		ELSE 1
	|	END AS Character
	|INTO GoodsTransferredBalanceMark
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(, ItemsLocationAttributes IN
	|		(SELECT
	|			DimensionKeys.Ref
	|		FROM
	|			DimensionKeys AS DimensionKeys)
	|	AND Organization = &Organization) AS GoodsTransferred
	|;
	|
	|
	|//////////////////////////////////////////////////////////////////////////////// 5 - Balances and quantity by registrar
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferred
	|FROM
	|	(SELECT
	|		GoodsTransferred.ItemsLocationAttributes,
	|		GoodsTransferred.CCDNumber,
	|		CASE
	|			WHEN ISNULL(Balance.CountBalance * Balance.Character, 0) < GoodsTransferred.CountBalance *
	|				ISNULL(Balance.Character, 1)
	|				THEN ISNULL(Balance.CountBalance, 0)
	|			ELSE GoodsTransferred.CountBalance
	|		END AS CountBalance
	|	FROM
	|		GoodsTransferredBalance AS GoodsTransferred
	|			LEFT JOIN GoodsTransferredBalanceMark AS Balance
	|			ON GoodsTransferred.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|			AND GoodsTransferred.CCDNumber = Balance.CCDNumber
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTransferredToRegistrar.ItemsLocationAttributes,
	|		GoodsTransferredToRegistrar.CCDNumber,
	|		CASE WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor),
	|			VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor)) THEN
	|			- GoodsTransferredToRegistrar.Count
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|			VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller),
	|			VALUE(Enum.BusinessTransactions.DamageAtToller),
	|			VALUE(Enum.BusinessTransactions.ProductionByToller2_5),
	|			VALUE(Enum.BusinessTransactions.DamageAtCustodian))
	|			AND GoodsTransferredToRegistrar.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			- GoodsTransferredToRegistrar.Count
	|		ELSE
	|			GoodsTransferredToRegistrar.Count
	|		END
	|	FROM
	|		AccumulationRegister.CompanyGoods AS GoodsTransferredToRegistrar
	|	WHERE
	|		GoodsTransferredToRegistrar.Recorder = &Recorder
	|		AND GoodsTransferredToRegistrar.Active
	|		AND GoodsTransferredToRegistrar.ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|		AND GoodsTransferredToRegistrar.Organization = &Organization) AS GoodsTransferred
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber
	|
	|HAVING
	|	SUM(GoodsTransferred.CountBalance) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT ALLOWED
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS
	|		Characteristic,
	|	CASE
	|		WHEN TT_Item.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END AS Purpose,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferredGrouping
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTransferred.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN Catalog.Products AS TT_Item
	|		ON DimensionKeys.Products = TT_Item.Ref
	|GROUP BY
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN TT_Item.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
	|	GoodsTransferred.CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7 Connection with goods from the consignment note
	|SELECT
	|	GoodsTransferredGrouping.Products AS Products,
	|	GoodsTransferredGrouping.Characteristic AS Characteristic,
	|	GoodsTransferredGrouping.Purpose AS Purpose,
	|	GoodsTransferredGrouping.Series AS Series,
	|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
	|	GoodsTransferredGrouping.CCDNumber AS CCDNumber,
	|	GoodsTransferredGrouping.OriginCountry AS OriginCountry,
	|	GoodsTransferredGrouping.CountBalance AS CountBalance,
	|	GoodsTransferredGrouping.CountBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
	|
	|FROM
	|	GoodsTransferredGrouping AS GoodsTransferredGrouping
	|		LEFT JOIN InvoiceGoods AS InvoiceGoods
	|		ON GoodsTransferredGrouping.Products = InvoiceGoods.Products
	|		AND GoodsTransferredGrouping.Characteristic = InvoiceGoods.Characteristic
	|		AND GoodsTransferredGrouping.Purpose = InvoiceGoods.Purpose
	|		AND GoodsTransferredGrouping.Series = InvoiceGoods.Series
	|		AND GoodsTransferredGrouping.CCDNumber = InvoiceGoods.CCDNumber
	|
	|ORDER BY
	|	ISNULL(InvoiceGoods.LineNumber, 99999)
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf