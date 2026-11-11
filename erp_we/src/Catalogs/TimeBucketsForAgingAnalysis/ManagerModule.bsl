#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InfobaseUpdate

// Performs the initial filling in of the reference list
//
Procedure CreateDefaultDebtClassificationOptionMonopoly() Export
	Query = New Query(
	"SELECT TOP 1
	|	1 AS Field
	|FROM
	|	Catalog.TimeBucketsForAgingAnalysis AS TimeBucketsForAgingAnalysis");
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		// Deferral mode - by calendar days
		DefaultElement = Catalogs.TimeBucketsForAgingAnalysis.CreateItem();
		
		DefaultElement.Description = NStr("vi = 'Bảng mã hiệu chuẩn';
											|ru = 'Стандартная классификация';
											|en = 'Standard classification'; fa = 'Standard classification';
											|it = 'Classificazione standard';
											|pl = 'Klasyfikacja standardowa';
											|tr = 'Standart sınıflandırma'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 1;
		NewInterval.UpperBoundOfInterval = 2;
		NewInterval.IntervalName = NStr("vi = 'Từ 1 đến 2 ngày';
										|ru = 'От 1 до 2 дней';
										|en = '1 to 2 days'; fa = '1 to 2 days';
										|it = 'Da 1 ai 2 giorni';
										|pl = 'Od 1 do 2 dni';
										|tr = '1 ila 2 gün'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 3;
		NewInterval.UpperBoundOfInterval = 14;
		NewInterval.IntervalName = NStr("vi = 'Từ 3 đến 14 ngày';
										|ru = 'От 3 до 14 дней';
										|en = '3 to 14 days'; fa = '3 to 14 days';
										|it = 'Dai 3 ai 14 giorni';
										|pl = 'Od 3 do 14 dni';
										|tr = '3 ila 14 gün'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 15;
		NewInterval.UpperBoundOfInterval = 29;
		NewInterval.IntervalName = NStr("vi = 'Từ 15 đến 29 ngày';
										|ru = 'От 15 до 29 дней';
										|en = '15 to 29 days'; fa = '15 to 29 days';
										|it = 'Dai 15 ai 29 giorni';
										|pl = 'Od 15 do 29 dni';
										|tr = '15 ila 29 gün'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 30;
		NewInterval.UpperBoundOfInterval = 44;
		NewInterval.IntervalName = NStr("vi = 'Từ 30 đến 44 ngày';
										|ru = 'От 30 до 44 дней';
										|en = '30 to 44 days'; fa = '30 to 44 days';
										|it = 'Dai 30 ai 44 giorni';
										|pl = 'Od 30 do 44 dni';
										|tr = '30''dan 44 güne kadar'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 45;
		NewInterval.UpperBoundOfInterval = 59;
		NewInterval.IntervalName = NStr("vi = '45 đến 59 ngày';
										|ru = 'От 45 до 59 дней';
										|en = '45 to 59 days'; fa = '45 to 59 days';
										|it = 'Dai 45 ai 59 giorni';
										|pl = 'Od 45 do 59 dni';
										|tr = '45 ila 59 gün'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 60;
		NewInterval.UpperBoundOfInterval = 179;
		NewInterval.IntervalName = NStr("vi = '60 đến 179 ngày';
										|ru = 'От 60 до 179 дней';
										|en = '60 to 179 days'; fa = '60 to 179 days';
										|it = 'Dai 60 ai 179 giorni';
										|pl = 'Od 60 do 179 dni';
										|tr = '60 ila 179 gün'");
		
		NewInterval = DefaultElement.Intervals.Add();
		NewInterval.LowerBoundOfInterval = 180;
		NewInterval.UpperBoundOfInterval = 9999999999;
		NewInterval.IntervalName = NStr("vi = 'Hơn 180 ngày';
										|ru = 'Свыше 180 дней';
										|en = 'Over 180 days'; fa = 'Over 180 days';
										|it = 'Oltre i 180 giorni';
										|pl = 'Ponad 180 dni';
										|tr = '180 günden fazla'");
		
		InfobaseUpdate.WriteData(DefaultElement);
	EndIf;
EndProcedure

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If FormType = "ListForm" 
		And Not Constants.UseSeveralDebtClassifications.Get() Then
		
		Parameters.Insert("Key", GeneralPurposeTMServerCall.DefaultDebtClassificationOption());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion
