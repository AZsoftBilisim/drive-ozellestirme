#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsNew() And Not DeletionMark Then
		Description = InformationRegisters.SetAccountingDimension.DimensionKeyName(ThisObject);
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
	|	InformationRegister.SetAccountingDimension AS RegisterData
	|WHERE
	|	RegisterData.DimensionKey = &Key
	|");
	Query.SetParameter("Key", Ref);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordManager = InformationRegisters.SetAccountingDimension.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection);
		RecordManager.Delete();
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
