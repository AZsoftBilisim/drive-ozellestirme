#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not WorkCentersWereFilledInCorrectly(Cancel) Then
		NotCheckedAttributeArray.Add("OptimizationCriteria");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

Function WorkCentersWereFilledInCorrectly(Cancel)
	
	Result = True;	
	
	QueryText = QueryTextWorkCentersWereFilledInCorrectly();
	Query = New Query(QueryText);
	Query.SetParameter("WorkCentersExclude", WorkCentersExclude.Unload());
	
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleResults.Next() Do
		If SampleResults.Exclude Then
			
			Result = False;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với dạng nguồn lực sản xuất ""%1"", tất cả nguồn lực sản xuất được liệt kê là loại trừ.';
					|ru = 'Для вида рабочего центра ""%1"" все рабочие центры указаны в качестве исключаемых.';
					|en = 'All work centers are specified as excluded from the ""%1"" work center type.'; fa = 'All work centers are specified as excluded from the ""%1"" work center type.';
					|it = 'Per il tipo del centro lavorativo ""%1"" tutti i centri lavorativi sono indicati come escludibili.';
					|pl = 'Dla rodzaju centrum pracy ""%1"" wszystkie centry wykonania prac są określone jako wykluczone.';
					|tr = '""%1"" türündeki iş merkezi için tüm iş merkezleri hariç tutulan olarak belirtildi.'"),
				SampleResults.WorkCenterTypePresentation);
				
			RowWithError = WorkCentersExclude.Find(SampleResults.WorkCenterType, "WorkCenterType");
			Field = CommonClientServer.PathToTabularSection(
				"WorkCentersExclude",
				RowWithError.LineNumber,
				"WorkCenterType");
			
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "Object", Cancel);
				
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function QueryTextWorkCentersWereFilledInCorrectly()
	
	Result = 
	"SELECT DISTINCT
	|	WorkCentersExclude.WorkCenterType,
	|	WorkCentersExclude.WorkCenter
	|INTO WorkCentersExclude
	|FROM
	|	&WorkCentersExclude AS WorkCentersExclude
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkCenters.WorkCenterType AS WorkCenterType,
	|	WorkCenters.WorkCenterType.Presentation AS WorkCenterTypePresentation,
	|	WorkCenters.Ref AS WorkCenter,
	|	CASE
	|		WHEN WorkCentersExclude.WorkCenter IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Exclude
	|FROM
	|	Catalog.WorkCenters AS WorkCenters
	|		LEFT JOIN WorkCentersExclude AS WorkCentersExclude
	|		ON WorkCenters.Ref = WorkCentersExclude.WorkCenter
	|			AND WorkCenters.WorkCenterType = WorkCentersExclude.WorkCenterType
	|WHERE
	|	WorkCenters.WorkCenterType IN
	|			(SELECT
	|				WorkCentersExclude.WorkCenterType
	|			FROM
	|				WorkCentersExclude)
	|TOTALS
	|	MIN(Exclude)
	|BY
	|	WorkCenterType";
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf