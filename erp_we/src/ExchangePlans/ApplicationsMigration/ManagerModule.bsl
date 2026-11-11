#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

Procedure FillInAuxiliaryData() Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ApplicationsMigration.DataAreaMainData AS DataAreaMainData
	|FROM
	|	ExchangePlan.ApplicationsMigration AS ApplicationsMigration
	|WHERE
	|	NOT ApplicationsMigration.ThisNode";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ValueManager = Constants.ApplicationsMigrationUsed.CreateValueManager();
		ValueManager.DataAreaAuxiliaryData = Selection.DataAreaMainData;
		ValueManager.Value = True;
		ValueManager.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf