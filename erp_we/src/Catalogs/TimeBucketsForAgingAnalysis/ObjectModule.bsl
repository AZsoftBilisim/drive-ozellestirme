#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NumberOfStages = Intervals.Count();
	
	If NumberOfStages < 2 Then
		Return;
	EndIf;
	
	For ExternalTag_ = 2 To NumberOfStages Do
	
		IndexOfPreviousStage  = ExternalTag_ - 2;
		IndexOfCurrentStage     = ExternalTag_ - 1;
		PreviousTermValue = Intervals[IndexOfPreviousStage].LowerBoundOfInterval;
		CurTermValue    = Intervals[IndexOfCurrentStage].LowerBoundOfInterval;
		
		// The value of the field of the lower border of the interval of the tabular part of the Intervals
		// should go in ascending order. This is necessary so
		// that accounts receivable can be attributed to only one stage.
		If CurTermValue <= PreviousTermValue Then
			
			ErrorText = NStr("vi = 'Giới hạn dưới trong dòng %IndexOfCurrentStage%
			| phải lớn hơn dòng %IndexOfPreviousStage%';
			|ru = 'Нижняя граница в строке %IndexOfCurrentStage%
			| должна быть больше, чем в строке %IndexOfPreviousStage%';
			|en = 'Lower limit in line %IndexOfCurrentStage%
			| must be greater than in line %IndexOfPreviousStage%'; fa = 'Lower limit in line %IndexOfCurrentStage%
			| must be greater than in line %IndexOfPreviousStage%';
			|it = 'Il limite inferiore della riga %IndexOfCurrentStage%
			| deve essere superiore a quello della riga %IndexOfPreviousStage%';
			|pl = 'Dolna granica w wierszu %IndexOfCurrentStage%
			|musi być większa, niż w wierszu %IndexOfPreviousStage%';
			|tr = 'Satırın alt sınırı %IndexOfCurrentStage%
			| satırdan büyük olmalıdır %IndexOfPreviousStage%'");
			ErrorText = StrReplace(ErrorText,"%IndexOfCurrentStage%",IndexOfCurrentStage + 1);
			ErrorText = StrReplace(ErrorText,"%IndexOfPreviousStage%",IndexOfPreviousStage + 1);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Intervals",IndexOfCurrentStage+1,"LowerBoundOfInterval"),
				,
				Cancel);
			
		EndIf;
			
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// Let's fill in the hidden props of the "Upper border of the Interval"
	
	NumberOfIntervals_       = Intervals.Count();
	NameOfTimeInterval = NStr("vi = 'Nhiều hơn %LowerBoundOfInterval% ngày';
								|ru = 'Свыше %LowerBoundOfInterval% дней';
								|en = 'Over %LowerBoundOfInterval% days'; fa = 'Over %LowerBoundOfInterval% days';
								|it = 'Oltre i %LowerBoundOfInterval% giorni';
								|pl = 'Ponad %LowerBoundOfInterval% dni';
								|tr = 'Günlerden %LowerBoundOfInterval% fazla'");
	NameOfIntervalFromTo  = NStr("vi = 'Từ %LowerBoundOfInterval% đến %UpperBoundOfInterval%%DaysOfDays%';
								|ru = 'От %LowerBoundOfInterval% до %UpperBoundOfInterval%%DaysOfDays%';
								|en = '%LowerBoundOfInterval% to %UpperBoundOfInterval%%DaysOfDays%'; fa = '%LowerBoundOfInterval% to %UpperBoundOfInterval%%DaysOfDays%';
								|it = 'Da %LowerBoundOfInterval% a %UpperBoundOfInterval%%DaysOfDays%';
								|pl = 'Od %LowerBoundOfInterval% do %UpperBoundOfInterval% %DaysOfDays%';
								|tr = '%LowerBoundOfInterval%''dan %UpperBoundOfInterval%%DaysOfDays%'");
	UpperBoundOfInterval    = 9999999999;
	
	If Intervals.Count() = 1 Then
		
		Intervals[0].UpperBoundOfInterval = UpperBoundOfInterval;
		Intervals[0].IntervalName = StrReplace(NameOfTimeInterval, "%LowerBoundOfInterval%", Intervals[0].LowerBoundOfInterval);
		
	ElsIf NumberOfIntervals_ > 1 Then
		
		For CurIndex__ = 1 To NumberOfIntervals_-1 Do
			
			PreviousStage = Intervals[CurIndex__-1];
			
			If CurIndex__ < NumberOfIntervals_ Then
				
				PreviousStage.UpperBoundOfInterval = Intervals[CurIndex__].LowerBoundOfInterval-1;
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromTo, "%LowerBoundOfInterval%", PreviousStage.LowerBoundOfInterval);
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromToPresentation, "%UpperBoundOfInterval%", PreviousStage.UpperBoundOfInterval);
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromToPresentation, "%DaysOfDays%", ?(PreviousStage.UpperBoundOfInterval = 1, " " + NStr("vi = 'ngày';
																																									|ru = 'дня';
																																									|en = 'day'; fa = 'روز';
																																									|it = 'del giorno';
																																									|pl = 'dnia';
																																									|tr = 'gün'"), " " + NStr("vi = 'ngày';
																																																|ru = 'дней';
																																																|en = 'days'; fa = 'روز';
																																																|it = 'di giorni';
																																																|pl = 'dni';
																																																|tr = 'günler'")));
				PreviousStage.IntervalName = NameOfIntervalFromToPresentation;
				
			EndIf;
			
			Intervals[NumberOfIntervals_-1].UpperBoundOfInterval = UpperBoundOfInterval;
			Intervals[NumberOfIntervals_-1].IntervalName = StrReplace(NameOfTimeInterval, "%LowerBoundOfInterval%", Intervals[NumberOfIntervals_-1].LowerBoundOfInterval);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
