#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	For Each RowData In RMCycle Do
		RowData.RMType = Catalogs.RMTypes.EmptyRef();
	EndDo;

	For Each RowData In OtherRMActivities Do
		RowData.RMType = Catalogs.RMTypes.EmptyRef();
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	If UseOfSubclasses Then
		
		If RMCycle.Count()<>0 Then
			RMCycle.Clear();
		EndIf;
		
		If OtherRMActivities.Count()<>0 Then
			OtherRMActivities.Clear();
		EndIf;
		
	EndIf;
	
	OwnSetOfProperties = True;
	If ValueIsFilled(PropertiesSet) Then
		Query = New Query;
		Query.SetParameter("PropertiesSet", ThisObject.PropertiesSet);
		Query.SetParameter("Ref", ThisObject.Ref);
		Query.Text =
		"SELECT TOP 1
		|	MaintenanceSchemes.Ref
		|FROM
		|	Catalog.MaintenanceSchemes AS MaintenanceSchemes
		|WHERE
		|	MaintenanceSchemes.Ref <> &Ref
		|	AND NOT MaintenanceSchemes.DeletionMark
		|	AND MaintenanceSchemes.PropertiesSet = &PropertiesSet";
		OwnSetOfProperties = Query.Execute().IsEmpty();
	EndIf;
	If OwnSetOfProperties And ValueIsFilled(PropertiesSet) Then
		
		PropertyManager.BeforeWriteObjectKind(
			ThisObject,
			?(ThisNodeClass, "Catalog_SubAssets", "Catalog_Assets"));
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not IsFolder Then
		
		If Not UseOfSubclasses Then
			
			// Checking the completion of planning rules
			Catalogs.MaintenanceSchemes.CheckingCompletionOfPlanningRules(ThisObject, NotCheckedAttributeArray, Cancel);
			
		EndIf;
		
		NotCheckedAttributeArray.Add("RunningTimeValues.AverageDailyValue");
		NotCheckedAttributeArray.Add("RunningTimeValues.MinimumCalculationPeriod");
		NotCheckedAttributeArray.Add("RunningTimeValues.MaximumCalculationPeriod");
		
		// Checking the completion of the operating time indicators
		For CurIndex__ = 0 To RunningTimeValues.Count()-1 Do
			
			String = RunningTimeValues[CurIndex__];
			
			If String.RecalculateAverageDailyValue Then
				
				If Not ValueIsFilled(String.MinimumCalculationPeriod) Then
					
					MessageText = NStr("vi = 'Chưa điền cột ""Kỳ tính toán tối thiểu"" trong dòng %1 của danh sách ""Chỉ số thời gian hoạt động""';
										|ru = 'Не заполнена колонка ""Минимальный период расчета"" в строке %1 списка ""Показатели наработки""';
										|en = 'The ""Minimum calculation period"" column in row %1 of the ""Operating time units"" list is required'; fa = 'The ""Minimum calculation period"" column in row %1 of the ""Operating time units"" list is required';
										|it = 'Colonna ""Periodo minimo di calcolo"" nella riga %1 dell''elenco ""Indicatori di tempo senza guasti"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Minimalny okres obliczenia"" w wierszu %1 listy ""Wskaźniki średniego czasu pracy""';
										|tr = '"" İşletim süresi"" listesinin %1 satırındaki ""Minimum hesaplama süresi"" sütunu doldurulmamış'");
					MessageText = StrTemplate(MessageText, RunningTimeValues[CurIndex__].LineNumber);
					
					CommonClientServer.MessageToUser(
						MessageText,
						ThisObject,
						CommonClientServer.PathToTabularSection("RunningTimeValues", RunningTimeValues[CurIndex__].LineNumber, "MinimumCalculationPeriod"),
						,
						Cancel);
					
				EndIf;
				
				If Not ValueIsFilled(String.MaximumCalculationPeriod) Then
					
					MessageText = NStr("vi = 'Chưa điền cột ""Kỳ tính toán tối đa"" trong dòng %1 của danh sách ""Chỉ số thời gian hoạt động""';
										|ru = 'Не заполнена колонка ""Максимальный период расчета"" в строке %1 списка ""Показатели наработки""';
										|en = 'The ""Maximum calculation period"" column in row %1 of the ""Operating time units"" list is required'; fa = 'The ""Maximum calculation period"" column in row %1 of the ""Operating time units"" list is required';
										|it = 'Colonna ""Periodo massimo di calcolo"" nella riga %1 dell''elenco ""Indicatori di tempo senza guasti"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Maksymalny okres obliczenia"" w wierszu %1 listy ""Wskaźniki średniego czasu pracy""';
										|tr = '"" İşletim Süresi"" listesinin %1 satırındaki ""Maksimum Hesaplama Süresi"" sütunu doldurulmamış'");
					MessageText = StrTemplate(MessageText, RunningTimeValues[CurIndex__].LineNumber);
						
					CommonClientServer.MessageToUser(
						MessageText,
						ThisObject,
						CommonClientServer.PathToTabularSection("RunningTimeValues", RunningTimeValues[CurIndex__].LineNumber, "MaximumCalculationPeriod"),
						,
						Cancel);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf
