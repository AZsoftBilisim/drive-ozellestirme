#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsNew() And Not DeletionMark Then
		CreateKeyAnalytics();
		Description = InformationRegisters.AccountingDimensionByPartners.DimensionKeyName(ThisObject);
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

#Region Other

Procedure DeleteKeyAnalytics()
	
	Query = New Query("
	|SELECT
	|	*
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS RegisterData
	|WHERE
	|	RegisterData.DimensionKey = &Key
	|");
	Query.SetParameter("Key", Ref);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordManager = InformationRegisters.AccountingDimensionByPartners.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection);
		RecordManager.Delete();
	EndDo;
	
EndProcedure

Procedure CreateKeyAnalytics()
	Query = New Query("
	|SELECT
	|	Keys.Ref AS Ref,
	|	Keys.Partner,
	|	Keys.Organization,
	|	Keys.Counterparty,
	|	Keys.Contract,
	|	Keys.LineOfBusiness
	|FROM
	|	Catalog.DimensionKeysOfAccountingByPartners AS Keys
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON Dimension.DimensionKey = Keys.Ref
	|WHERE
	|	Keys.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|");
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		RecordManager = InformationRegisters.AccountingDimensionByPartners.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection);
		RecordManager.DimensionKey = Selection.Ref;
		RecordManager.Write(True);
	EndIf;
EndProcedure

#EndRegion

#EndRegion

#EndIf
