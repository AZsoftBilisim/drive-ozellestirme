#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Value Then
		
		Settings = New Structure("AutoUploadDeleteTask");
		
		QueryText = "
		|SELECT
		|	Settings.DataSource,
		|	Settings.AutoimportJobID
		|FROM
		|	InformationRegister.MasterDataImportSettings AS Settings";
		
		Query = New Query;
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If ValueIsFilled(Selection.AutoimportJobID) Then
				InformationRegisters.MasterDataImportSettings.RecordSourceSettings(Selection.DataSource, Settings, True);
			EndIf;
		EndDo;
	
	EndIf;
	
EndProcedure

#EndRegion

#EndIf