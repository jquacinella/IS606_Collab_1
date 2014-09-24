library(ggplot2)

# costs to make our sammies
cost.hamSam <- 3.50;
cost.turkeySam <- 4.00;
cost.veggieSam <- 2.50;

# prices we sell our sammies for
price.hamSam <- 6.50;
price.turkeySam <- 6.50;
price.veggieSam <- 5;

# number of days  in simulation
days <- 130;
numSimulations <- 10000;

# calculate poisson lambdas from data
salesData <- read.csv("sales.csv")
lambda.ham <- mean(salesData$demand.ham)
lambda.turkey <- mean(salesData$demand.turkey)
lambda.veggie <- mean(salesData$demand.veggie)


runSimulation <- function(stock.begin.hamSam, stock.begin.turkeySam, stock.begin.veggieSam, withStorage=FALSE) {
  # lets initialize our stock to nothing (will be setup at beginning of each iter)
  stock.hamSam <- 0;
  stock.turkeySam <- 0;
  stock.veggieSam <- 0;

  # profit results for overall simulation
  total.profits <- numeric(numSimulations); 

  # Lets do a bunch of simulations, with each simulation based on 'days'
  for(simulation in 1:numSimulations) {
    # Initialize data per simulation 
    # (we pre-initialize memory to avoid having to allocate it constantly in the loops, helps with speed)
    costs <- numeric(days);
    revenues <- numeric(days);
    orders.hamSam <- numeric(days);
    orders.turkeySam <- numeric(days);
    orders.veggieSam <- numeric(days);

    # Do simulation of N days
    for (n in 1:days) {
      # Init this day with a new stock of food
      if(withStorage) {
        # If we have storage then we only need to bring in what we need
        # i.e., if we have 5 ham sammies from yesterday, and we need to have 18, then we only need to make 12 more
        # Simplistic modeling: limits on storage? maybe we need to discard after x days?
        
        # Do we need to bring in more ham sammies? If so, only bring in that many; 
        # otherwise no need to bring ham sammies today
        delta.hamSam <- 0;
        if(stock.begin.hamSam - stock.hamSam) { delta.hamSam <- stock.begin.hamSam - stock.hamSam;}

        # Do we need to bring in more turkey sammies? If so, only bring in that many; 
        # otherwise no need to bring turkey sammies today
        delta.turkeySam <- 0;
        if(stock.begin.turkeySam - stock.turkeySam) { delta.turkeySam <- stock.begin.turkeySam - stock.turkeySam;}

        # Do we need to bring in more veggie sammies? If so, only bring in that many; 
        # otherwise no need to bring veggie sammies today
        delta.veggieSam <- 0;
        if(stock.begin.veggieSam - stock.veggieSam) { delta.veggieSam <- stock.begin.veggieSam - stock.veggieSam;}

        # Update out stocks with what we bring in at beginning of day
        stock.hamSam <- stock.hamSam + delta.hamSam;
        stock.turkeySam <- stock.turkeySam + delta.turkeySam;
        stock.veggieSam <- stock.veggieSam + delta.veggieSam;

        # Update cost data (note only for what we bring in, which is delta)
        costs[n] <- cost.hamSam * delta.hamSam + cost.turkeySam * delta.turkeySam + cost.veggieSam * delta.veggieSam;
      }
      else {
        # Update out stocks with what we bring in at beginning of day (With no storage, we bring in constant supply)
        stock.hamSam <- stock.begin.hamSam; 
        stock.turkeySam <- stock.begin.turkeySam; 
        stock.veggieSam <- stock.begin.veggieSam; 

        # Update cost data
        costs[n] <- cost.hamSam * stock.hamSam + cost.turkeySam * stock.turkeySam + cost.veggieSam * stock.veggieSam;
      }
      
   
      # TODO: vectorize at some point
      
      # Get this from sub-models
      cust.hamSam <- ceiling(rpois(1, lambda.ham));
      cust.turkeySam <- ceiling(rpois(1, lambda.turkey));
      cust.veggieSam <- ceiling(rpois(1, lambda.veggie));

      # ham sammies
      if (stock.hamSam >= cust.hamSam) { 
        order.hamSam <- cust.hamSam;
        stock.hamSam <- stock.hamSam - order.hamSam;
      }
      else { 
        order.hamSam <- stock.hamSam;
        stock.hamSam <- 0;
      }
      
      # turkey sammies
      if (stock.turkeySam >= cust.turkeySam) { 
        order.turkeySam <- cust.turkeySam;
        stock.turkeySam <- stock.turkeySam - order.turkeySam;
      }
      else { 
        order.turkeySam <- stock.turkeySam;
        stock.turkeySam <- 0;
      }
      
      # veggie sammies
      if (stock.veggieSam >= cust.veggieSam) { 
        order.veggieSam <- cust.veggieSam;
        stock.veggieSam <- stock.veggieSam - order.veggieSam;
      }
      else { 
        order.veggieSam <- stock.veggieSam;
        stock.veggieSam <- 0;
      }
      
      # Update revenue data
      revenues[n] <- price.hamSam * order.hamSam + price.turkeySam * order.turkeySam + price.veggieSam * order.veggieSam;
    }

    # update aggregates over simulations
    total.profits[simulation] = sum(revenues - costs); 
  }

  # Return vector of the total profits from the N simulations
  return(total.profits);
}

# Run five simulations
total.profits.sim1 <- runSimulation(14,14,8);
total.profits.sim2 <- runSimulation(18,20,10);
total.profits.sim3 <- runSimulation(18,20,10, TRUE);
total.profits.sim4 <- runSimulation(lambda.ham, lambda.turkey, lambda.veggie);
total.profits.sim5 <- runSimulation(lambda.ham, lambda.turkey, lambda.veggie, TRUE);
total.profits.sim6 <- runSimulation(25,37,24, TRUE);

# After all simulations done, show profit graphs
p<-ggplot() + 
  geom_histogram(data=data.frame(profit=total.profits.sim1), aes(x=profit, fill="1"), alpha=0.4) + 
  geom_histogram(data=data.frame(profit=total.profits.sim2), aes(x=profit, fill="2"), alpha=0.4) + 
  geom_histogram(data=data.frame(profit=total.profits.sim3), aes(x=profit, fill="3"), alpha=0.4) + 
  geom_histogram(data=data.frame(profit=total.profits.sim4), aes(x=profit, fill="4"), alpha=0.4) + 
  geom_histogram(data=data.frame(profit=total.profits.sim5), aes(x=profit, fill="5"), alpha=0.4) + 
  geom_histogram(data=data.frame(profit=total.profits.sim6), aes(x=profit, fill="6"), alpha=0.4) + 
  xlab('Profit ($)') + 
  ylab('Frequency') + 
  ggtitle("Profit Distribution Based on Various Models") + 
  scale_fill_manual("", values=c("red", "green", "blue", "purple", "pink", "orange"), 
                        breaks=c("1", "2", "3", "4", "5", "6"), 
                        labels=c("Constant Supply 14,14,8, No Storage", 
                          "Constant Supply 18,20,10, No Storage", 
                          "Constant Supply 18,20,10 with Storage", 
                          "Variable Supply, No Storage",
                          "Variable Supply, Storage",
                          "Max Demand Supply w/ Storage"));
p

# Save profit graph to disk
ggsave(filename="profitSimulation.jpg", plot=p);