function [xtick_labels,xtick_positions] = myticks (data)
% Extract the required columns
dates = datetime(data.DATE, 'InputFormat', 'yyyy-MM-dd');

% Determine the seasons for the first two years
years = unique(year(dates));
start_year = years(1);
end_year = years(2);
date_range = dates(year(dates) == start_year | year(dates) == end_year);

% Map dates to seasons
seasons = strings(size(date_range));
for i = 1:length(date_range)
    m = month(date_range(i));
    d = day(date_range(i));
    
    if (m == 12 && d >= 21) || (m <= 2) || (m == 3 && d <= 20)
        seasons(i) = "Winter";
    elseif (m == 3 && d >= 21) || (m <= 6) || (m == 6 && d <= 20)
        seasons(i) = "Spring";
    elseif (m == 6 && d >= 21) || (m <= 9) || (m == 9 && d <= 20)
        seasons(i) = "Summer";
    elseif (m == 9 && d >= 21) || (m <= 12) || (m == 12 && d <= 20)
        seasons(i) = "Fall";
    end
end

% Create x-tick labels based on season transitions
[unique_seasons, idx] = unique([string(year(date_range)), seasons], 'rows', 'stable');
xtick_positions = idx;
xtick_labels = strcat(unique_seasons(:, 2), " ", unique_seasons(:, 1));

% Plot the data

xticks(xtick_positions);
xticklabels(xtick_labels);
xtickangle(45);
