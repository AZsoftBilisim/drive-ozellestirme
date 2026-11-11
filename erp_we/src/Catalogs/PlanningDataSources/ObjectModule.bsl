#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;

	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
		
	
	If IsFolder Then
		
		Return;
		
	EndIf;
	
	NamesArray = StrSplit(DCSTemplateName, ".", False);
	If NamesArray.Count() = 3 Then
		
		DataCompositionSchema = New ValueStorage(Undefined);
		
	ElsIf TypeOf(DataCompositionSchema.Get()) <> Type("DataCompositionSchema") Then
		
		DataCompositionSchema = New ValueStorage(New DataCompositionSchema);
		
	EndIf;
	
	If ValueIsFilled(DCSTemplateName) And DCSTemplateVersion = 0 Then
	
		DCSTemplateVersion = Catalogs.PlanningDataSources.CurVersionOfDCSTemplates();
		
	ElsIf Not ValueIsFilled(DCSTemplateName) Then
		
		DCSTemplateVersion = 0;
	
	EndIf; 
	
EndProcedure

#EndRegion

#EndIf