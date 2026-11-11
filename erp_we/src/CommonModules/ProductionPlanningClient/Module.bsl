////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of production planning and production schedule calculation
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


// Opens the workplace to change the availability of the RC view
//
// Parameters:
//  WorkCenterType	- CatalogRef.WorkCenterTypes - View of the work center to change availability for
//  IntervalDate		- Date - The date when you want to change availability.
//
Procedure ChangeAvailabilityOfRCView(WorkCenterType, IntervalDate) Export

	FormParameters = New Structure;
	FormParameters.Insert("WorkCenterType", WorkCenterType);
	FormParameters.Insert("BeginOfPeriod", IntervalDate);
	FormParameters.Insert("PeriodEnding", IntervalDate);
	
	OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form", FormParameters);
	
EndProcedure


#EndRegion
