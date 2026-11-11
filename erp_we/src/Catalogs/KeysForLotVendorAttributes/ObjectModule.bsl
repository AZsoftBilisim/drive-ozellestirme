#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsNew() And Not DeletionMark Then
		CreateKeyAnalytics();
		Description = Catalogs.KeysForLotVendorAttributes.DimensionKeyName(ThisObject);
	EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DeleteKeyAnalytics();
	
EndProcedure

#EndRegion

#Region Private

Procedure CreateKeyAnalytics()
	Query = New Query("
	|SELECT
	|	Keys.Ref AS Ref,
	|	Keys.FinancialAccountingGroup,
	|	Keys.Vendor,
	|	Keys.Counterparty,
	|	Keys.VATTaxation,
	|	Keys.VATRate,
	|	Keys.AssetTaxClass,
	|	Keys.RowCode
	|FROM
	|	Catalog.KeysForLotVendorAttributes AS Keys
	|	LEFT JOIN InformationRegister.LotVendorAttributes AS Dimension
	|		ON Dimension.DimensionKey = Keys.Ref
	|WHERE
	|	Keys.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|");
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		RecordManager = InformationRegisters.LotVendorAttributes.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection);
		RecordManager.DimensionKey = Selection.Ref;
		RecordManager.Write(True);
	EndIf;
EndProcedure

Procedure DeleteKeyAnalytics()
	
	Query = New Query("
	|SELECT
	|	*
	|FROM
	|	InformationRegister.LotVendorAttributes AS RegisterData
	|WHERE
	|	RegisterData.DimensionKey = &Key
	|");
	Query.SetParameter("Key", Ref);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordManager = InformationRegisters.LotVendorAttributes.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection);
		RecordManager.Delete();
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
