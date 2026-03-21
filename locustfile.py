from locust import HttpUser, task, between

class BookMyShowShopper(HttpUser):
  wait_time = between(1, 4)

  @task
  def browse_homepage(self):
    self.client.get("/")
